# terraform-azure-load-balancer

## Usage

Examples for this module along with various configurations can be found in the [examples/](examples/) folder.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.26.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.73.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_resource_names"></a> [azure\_resource\_names](#module\_azure\_resource\_names) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-resource-names.git | v2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_resource_attributes"></a> [azure\_resource\_attributes](#input\_azure\_resource\_attributes) | Attributes used to describe Azure resources | <pre>object({<br>    project     = string<br>    environment = string<br>    location    = optional(string, "Canada Central")<br>    instance    = number<br>  })</pre> | n/a | yes |
| <a name="input_frontend"></a> [frontend](#input\_frontend) | n/a | <pre>map(object({<br>    ip_address_allocation = optional(string, "Static") // Static or Dynamic<br>    ip_address_version    = optional(string, "IPv4")   // `IPv4` or `IPv6`<br><br>    // internal type<br>    subnet_id          = optional(string)<br>    private_ip_address = optional(string) // Only required if Static<br><br>    // public type<br>    public_ip_prefix_id  = optional(string)<br>    public_ip_address_id = optional(string)<br>    public_ip_address = optional(object({<br>      name = optional(string) // Will use the frontend name by default<br><br>      domain_name_label = optional(string)<br>      reverse_fqdn      = optional(string)<br><br>      ip_tags                 = optional(map(string)) // IP Tag `RoutingPreference` requires multiple `zones` and `Standard` SKU to be set<br>      idle_timeout_in_minutes = optional(number, 4)   // The value can be set between 4 and 30 minutes<br><br>      ddos_protection = optional(object({<br>        mode    = string // Possible values are `Disabled`, `Enabled`, and `VirtualNetworkInherited`. Defaults to `VirtualNetworkInherited`.<br>        plan_id = string // `ddos_protection_plan_id` can only be set when `ddos_protection_mode` is `Enabled`<br>      }))<br>    }))<br><br>    backend_name = string<br>    vm_backend_addresses = optional(list(object({ // Only useful for VMs<br>      name               = string<br>      virtual_network_id = string<br>      ip_address         = string<br>    })), [])<br><br>    lb_rules = optional(list(object({<br>      name        = optional(string)<br>      destination = list(string)<br><br>      disable_outbound_snat   = optional(bool, false)<br>      floating_ip_enabled     = optional(bool, false) // Required to configure a SQL AlwaysOn Availability Group.<br>      tcp_reset_enabled       = optional(bool, false)<br>      idle_timeout_in_minutes = optional(number, 4) // between 4 and 30 minutes<br><br>      probe = optional(object({<br>        destination         = list(string) // Format as [protocol, port, request_path]<br>        interval_in_seconds = optional(number, 5)<br>        number_of_probes    = optional(number, 2)<br>      }))<br>    })), [])<br><br>    nat_rules = optional(list(object({<br>      name        = optional(string)<br>      vm_type     = optional(string, "vmss") // vm, vmss<br>      destination = list(string)<br><br>      floating_ip_enabled     = optional(bool, false) // Required to configure a SQL AlwaysOn Availability Group.<br>      tcp_reset_enabled       = optional(bool, false)<br>      idle_timeout_in_minutes = optional(number, 4) // between 4 and 30 minutes<br>    })), [])<br>  }))</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the resource group where the load balancer resources will be imported. | `string` | n/a | yes |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | (Optional) Specifies the Edge Zone within the Azure Region where this Public IP and Load Balancer should exist. Changing this forces new resources to be created. | `list(number)` | `[]` | no |
| <a name="input_edge_zone"></a> [edge\_zone](#input\_edge\_zone) | (Optional) Specifies the Edge Zone within the Azure Region where this Public IP and Load Balancer should exist. Changing this forces new resources to be created. | `string` | `null` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | (Optional) The SKU of the Azure Load Balancer. Accepted values are Basic and Standard. | `string` | `"Basic"` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | (Optional) The SKU tier of this Load Balancer. Possible values are `Global` and `Regional`. Defaults to `Regional`. Changing this forces a new resource to be created. | `string` | `"Regional"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | (Optional) Defined if the loadbalancer is private or public. This determines if a Public IP Address is created for the load balancer. | `string` | `"private"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_address_pool_id"></a> [backend\_address\_pool\_id](#output\_backend\_address\_pool\_id) | n/a |
| <a name="output_lb_rules"></a> [lb\_rules](#output\_lb\_rules) | n/a |
| <a name="output_load_balancer_id"></a> [load\_balancer\_id](#output\_load\_balancer\_id) | n/a |
| <a name="output_nat_pool_rule_ids"></a> [nat\_pool\_rule\_ids](#output\_nat\_pool\_rule\_ids) | n/a |
| <a name="output_nat_rule_ids"></a> [nat\_rule\_ids](#output\_nat\_rule\_ids) | n/a |
| <a name="output_public_ip_addresses"></a> [public\_ip\_addresses](#output\_public\_ip\_addresses) | n/a |
<!-- END_TF_DOCS -->

## History

| Date       | Release | Change                                                   |
| ---------- | ------- | -------------------------------------------------------- |
| 2025-01-25 | v1.0.0  | initial commit                                           |
