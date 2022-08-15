# BIG-IP Next CM module

<!-- markdownlint-disable no-inline-html no-bare-urls -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.31 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.cm_bigip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.ha](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.cm](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_subnetwork.management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_compute_zones.zones](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bigip_next_service_account"></a> [bigip\_next\_service\_account](#input\_bigip\_next\_service\_account) | The service account used by BIG-IP Next instances. This will be used to create<br>firewall rules to allow BIG-IP CM and BIG-IP Next instance communication. | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | A fully-qualified Compute Engine image or family name to use with the instances.<br>Must be of the format `projects/project-id/global/images/image-name` or<br>`projects/project-id/global/images/family/family-name`. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name to use for generated resources. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project identifier where the cluster will be created. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The service account that will be used for the BIG-IP Next CM instances. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Fully-qualified subnet self-links for each VPC network that BIG-IP Next CM<br>instances will be attached to. | <pre>object({<br>    management = string<br>  })</pre> | n/a | yes |
| <a name="input_ip_assignments"></a> [ip\_assignments](#input\_ip\_assignments) | n/a | <pre>list(object({<br>    offsets         = list(number)<br>    floating_offset = number<br>  }))</pre> | <pre>[<br>  {<br>    "floating_offset": null,<br>    "offsets": []<br>  }<br>]</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional map of *labels* to add to the instances. | `map(string)` | `{}` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The machine type to use for BIG-IP Next CM VM; this may be a standard GCE<br>machine type, or a customised VM ('custom-VCPUS-MEM\_IN\_MB'). Default value is<br>'e2-standard-8'. | `string` | `"e2-standard-8"` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | An optional map of metadata values that will be applied to the instances. Use<br>this to add user-data configuration, for example. | `map(string)` | `{}` | no |
| <a name="input_min_cpu_platform"></a> [min\_cpu\_platform](#input\_min\_cpu\_platform) | An optional constraint used when scheduling the BIG-IP VMs; this value prevents<br>the VMs from being scheduled on hardware that doesn't meet the minimum CPU<br>micro-architecture, and if specified it must be compatible with the value of<br>'machine-type'. Default value is empty. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | An optional list of *network tags* to add to the instances. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_addresses"></a> [instance\_addresses](#output\_instance\_addresses) | A map of instance name to assigned private IP addresses and alias CIDRs on each interface. |
| <a name="output_instance_public_addresses"></a> [instance\_public\_addresses](#output\_instance\_public\_addresses) | A map of instance name to external public IP addresses on each interface. |
| <a name="output_self_links"></a> [self\_links](#output\_self\_links) | A list of self-links of the BIG-IP instances. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html no-bare-urls -->
