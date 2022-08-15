#!/bin/sh
#
# Script to create a bootable GCE disk image from a beta F5 OVA download.
#
# The script is meant to be safely re-entrant as much as possible so it can be
# used interactively for testing.

LOCAL_CACHE=${LOCAL_CACHE:-/tmp/cache}
ROOT_MNT=${ROOT_MNT:-/mnt/root}
BOOT_MNT=${BOOT_MNT:-/mnt/boot}

# Write an error message to stderr and exit, attempting to unmount BIG-IQ volumes
error()
{
    echo "$0: ERROR: $*" >&2
    umount_targets
    exit 1
}

# Write a message to stderr
info()
{
    echo "$0: INFO: $*" >&2
}

# Unmount partitions and clean up LVM.
# NOTE: This function will not raise an error if clean up fails as it may be
# part of exit handling.
umount_targets()
{
    while read -r d; do
        mount 2>/dev/null | grep -Eq "^${d}\s+" || continue
        umount "${d}" || info "Failed to umount ${d}; exit code $?"
    done <<EOF
/dev/sdb1
/dev/mapper/vg0-home
/dev/mapper/vg0-var
/dev/mapper/vg0-usr
/dev/mapper/vg0-root
EOF
    if command -v vgchange > /dev/null && command -v dmsetup > /dev/null && command -v pvscan > /dev/null; then
        vgchange -an vg0 || info "Failed to deactivate vg0"
        dmsetup ls | awk '/vg0/ {print $1}' | xargs -rn 1 dmsetup remove || \
            info "Failed to remove stale device-mapper entries"
        pvscan --cache || info "Failed to reset PV cache; exit code $?"
    fi
    return 0
}

# Quick sanity check - if any BIG-IP volumes are still mounted return 1 (false)
verify_targets_unmounted()
{
    mount 2>/dev/null | grep -Eq "${ROOT_MNT}" && return 1
    return 0
}

# Try to unmount BIG-IP volumes on ctrl-c, etc.
trap umount_targets INT TERM

[ $(($#)) -gt 0 ] || error "Source files must be provided"

info "Downloading files"
mkdir -p "${LOCAL_CACHE}" || error "Failed to create ${LOCAL_CACHE}; exit code $?"
for f in "$@"; do echo "${f}"; done | gsutil -m cp -n -I "${LOCAL_CACHE}/" || \
    error "Failed to download files from GCS"

BASE_IMAGE="$(find "${LOCAL_CACHE}" -regextype posix-extended -type f -regex '.*\.ova$' | sort -r | head -n 1)"
if [ -n "${BASE_IMAGE}" ]; then
    info "Extracting files from ova"
    tar xf "${BASE_IMAGE}" -C "${LOCAL_CACHE}/" || \
        error "Failed to untar ${BASE_IMAGE}; exit code $?"
    BASE_IMAGE="$(find "${LOCAL_CACHE}" -regextype posix-extended -type f -regex '.*-disk1\.vmdk$' | sort -r | head -n 1)"
    BASENAME="$(basename "${BASE_IMAGE}" -disk1.vmdk)"
    BASE_IMAGE_TYPE=vmdk
else
    BASE_IMAGE="$(find "${LOCAL_CACHE}" -regextype posix-extended -type f -regex '.*\.qcow2?(\.zip)?$' | sort -r | head -n 1)"
    [ -n "${BASE_IMAGE}" ] || error "Didn't find the base BIG-IP Next qcow2 image"
    if [ -n "${BASE_IMAGE##*qcow}" ] && [ "${BASE_IMAGE##*qcow}" != "2" ]; then
        info "Extracting qcow2 from zip"
        unzip -u "${BASE_IMAGE}" -d "${LOCAL_CACHE}/" || \
            error "Failed to unzip ${BASE_IMAGE}; exit code $?"
        BASE_IMAGE="$(find "${LOCAL_CACHE}" -regextype posix-extended -type f -regex '.*\.qcow2?$' | sort -r | head -n 1)"
    fi
    BASENAME="$(basename "$(basename "${BASE_IMAGE}" .qcow2)" .qcow)"
    BASE_IMAGE_TYPE=qcow2
fi
[ -n "${BASE_IMAGE}" ] || error "Didn't find the base BIG-IP Next image"
info "Processing image from ${BASE_IMAGE}"

info "Locating target disk"
DISK_NAME="$(curl -sf --retry 20 -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/disks/?recursive=true | jq -r '.[] | select(.index == 1) | .deviceName')"
[ -n "${DISK_NAME}" ] || error "Instance is missing a second disk"
TARGET_DEV="/dev/disk/by-id/google-${DISK_NAME}"
[ -b "${TARGET_DEV}" ] || error "Block device ${TARGET_DEV} is missing"

info "Writing ${BASE_IMAGE} to ${TARGET_DEV}"
qemu-img convert -f "${BASE_IMAGE_TYPE}" -O host_device "${BASE_IMAGE}" "${TARGET_DEV}" || \
    error "Failed to copy ${BASE_IMAGE} to ${TARGET_DEV}; exit code $?"

info "Mounting filesystems"
mkdir -p "${ROOT_MNT}" "${BOOT_MNT}" || \
    error "Failed to create mount point ${ROOT_MNT} or ${BOOT_MNT}; exit code $?"
pvscan --cache -aay "${TARGET_DEV}-part2" || \
    error "Failed to add PVs, VGs, and LVs from ${TARGET_DEV}-part2; exit code $?"
sleep 2
while read -r d m; do
    mount "${d}" "${m}" || \
        error "Failed to mount ${d} at ${m}; exit code $?"
done <<EOF
/dev/vg0/root ${ROOT_MNT}
${TARGET_DEV}-part1 ${BOOT_MNT}
EOF

# Change grub.cfg to meet GCP requirements
info "Modifying grub.cfg"
sed -E -i -e '/^splashimage/d' \
    -e '/^\s+linux/s/\s+(console=ttyS?0|quiet|rhgb)//g' \
    -e '/^\s+linux/s/$/ console=ttyS0,38400n8d/' \
    "${BOOT_MNT}/grub/grub.cfg" || error "Failed to update grub.cfg; sed exit code $?"

# Prefer GCE as the sole cloud-init datasource
info "Adding cloud-init override file 99-zzz-gce.cfg"
cat <<EOD > "${ROOT_MNT}/etc/cloud/cloud.cfg.d/99-zzz-gce.cfg" || error "Failed to create 99-zzz-gce.cfg"
# Prefer to use the upstream GCE sources; BIG-IP Next shouldn't be using GCP
# specific packages but set this just in case
system_info:
  package_mirrors:
    - arches: [i386, amd64]
      failsafe:
        primary: http://archive.ubuntu.com/ubuntu
        security: http://security.ubuntu.com/ubuntu
      search:
        primary:
          - http://%(region)s.gce.archive.ubuntu.com/ubuntu/
          - http://%(availability_zone)s.gce.clouds.archive.ubuntu.com/ubuntu/
          - http://gce.clouds.archive.ubuntu.com/ubuntu/
        security: []
    - arches: [armhf, armel, default]
      failsafe:
        primary: http://ports.ubuntu.com/ubuntu-ports
        security: http://ports.ubuntu.com/ubuntu-ports

# Use metadata server for NTP
ntp:
  enabled: true
  ntp_client: auto
  servers:
    - metadata.google.internal

# Only process GCE datasource
datasource_list: [GCE]
EOD

info "Unmounting volumes"
sync
umount_targets
verify_targets_unmounted || error "One or more target filesystems are still mounted; exiting"

PROJECT_ID="$(curl -sf -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/project/project-id)"
read -r INSTANCE_NAME INSTANCE_ZONE <<EOF
$(curl -sf -H 'Metadata-Flavor: Google' -H 'Content-Type: application/json' http://169.254.169.254/computeMetadata/v1/instance/?recursive=true | jq -r '[.name, .zone|split("/")[-1]]| join(" ")')
EOF
read -r DISK_ZONE DISK_NAME <<EOF
$(gcloud compute instances describe "${INSTANCE_NAME}" --project "${PROJECT_ID}" --zone "${INSTANCE_ZONE}" --format json | jq -r '.disks[]|select(.index == 1)|.source|split("/")|[.[8], .[10]]| join(" ")')
EOF
info "Creating image from ${DISK_NAME}"
IMG_NAME="${IMG_NAME:-"$(echo "${BASENAME}" | tr -d '\n' | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]_-' '-')-custom"}"
FAMILY_NAME="${FAMILY_NAME:-"$(echo "${IMG_NAME}" |grep -Eo '([a-z]+-)+[0-9]+(-[0-9]+)')"}"
gcloud compute images create "${IMG_NAME}" \
    --source-disk="${DISK_NAME}" \
    --source-disk-zone="${DISK_ZONE}" \
    --description="Custom BIG-IP Next image based on $(basename "${BASE_IMAGE}")" \
    --family="${FAMILY_NAME}" \
    --guest-os-features=MULTI_IP_SUBNET \
    --force || \
    error "Failed to create VM image from ${DISK_NAME}; exit code $?"

info "Provisioning complete"
