# Setup

The Terraform in this folder will be executed before creating resources and can
be used to setup service accounts, service principals, etc, that are used by the
inspec-* verifiers.

## Configuration

Create a local `terraform.tfvars` file that configures the testing project
constraints.

```hcl
# The GCP project identifier to use
project_id  = "my-gcp-project"

# The single Compute Engine region where the resources will be created
region = "us-west1"

# Optional labels to add to resources
labels = {
    "owner" = "tester-name"
}

# OPTIONAL: Any additional SSH public keys to add to generated SSH key, when
# setting through per-VM metadata.
ssh_keys = [
    "ssh-rsa AAAA.... user@example.com",
]
```

<!-- markdownlint-disable no-inline-html no-bare-urls -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.31 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.3 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | memes/private-bastion/google | 2.0.2 |
| <a name="module_bigip_sa"></a> [bigip\_sa](#module\_bigip\_sa) | terraform-google-modules/service-accounts/google | 4.1.1 |
| <a name="module_vpcs"></a> [vpcs](#module\_vpcs) | terraform-google-modules/network/google | 5.2.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.test_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.test_cm_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [local_file.harness_tfvars](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.ssh_privkey](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.ssh_pubkey](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_pet.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [random_shuffle.zones](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [google_compute_zones.zones](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [http_http.test_address](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | n/a | `map(string)` | `{}` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | n/a | `list(string)` | `[]` | no |
| <a name="input_test_source_cidrs"></a> [test\_source\_cidrs](#input\_test\_source\_cidrs) | n/a | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bigip_cm_sa"></a> [bigip\_cm\_sa](#output\_bigip\_cm\_sa) | n/a |
| <a name="output_harness_tfvars"></a> [harness\_tfvars](#output\_harness\_tfvars) | n/a |
| <a name="output_ssh_privkey_path"></a> [ssh\_privkey\_path](#output\_ssh\_privkey\_path) | n/a |
| <a name="output_ssh_pubkey_path"></a> [ssh\_pubkey\_path](#output\_ssh\_pubkey\_path) | n/a |
| <a name="output_ssh_pubkeys"></a> [ssh\_pubkeys](#output\_ssh\_pubkeys) | n/a |
| <a name="output_tunnel_command"></a> [tunnel\_command](#output\_tunnel\_command) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html no-bare-urls -->
