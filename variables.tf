variable "azure_resource_attributes" {
  description = "Attributes used to describe Azure resources"
  type = object({
    project     = string
    environment = string
    location    = optional(string, "Canada Central")
    instance    = number
  })
  nullable = false
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group where the load balancer resources will be imported."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) A mapping of tags to assign to the resource."
}

##############
### SHARED ###
##############

variable "type" {
  type        = string
  default     = "private"
  description = "(Optional) Defined if the loadbalancer is private or public. This determines if a Public IP Address is created for the load balancer."

  validation {
    condition     = var.type == "private" || var.type == "public"
    error_message = "The type value must be set to either \"private\" or \"public\"."
  }
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Public IP and Load Balancer should exist. Changing this forces new resources to be created."
}

variable "availability_zones" {
  type        = list(number)
  default     = []
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Public IP and Load Balancer should exist. Changing this forces new resources to be created."
}

#####################
### Load Balancer ###
#####################

variable "sku" {
  type        = string
  default     = "Basic"
  description = "(Optional) The SKU of the Azure Load Balancer. Accepted values are Basic and Standard."
}

variable "sku_tier" {
  type        = string
  default     = "Regional"
  description = "(Optional) The SKU tier of this Load Balancer. Possible values are `Global` and `Regional`. Defaults to `Regional`. Changing this forces a new resource to be created."
}

variable "frontend" {
  type = map(object({
    ip_address_allocation = optional(string, "Static") // Static or Dynamic
    ip_address_version    = optional(string, "IPv4")   // `IPv4` or `IPv6`

    // internal type
    subnet_id          = optional(string)
    private_ip_address = optional(string) // Only required if Static

    // public type
    public_ip_prefix_id  = optional(string)
    public_ip_address_id = optional(string)
    public_ip_address = optional(object({
      name = optional(string) // Will use the frontend name by default

      domain_name_label = optional(string)
      reverse_fqdn      = optional(string)

      ip_tags                 = optional(map(string)) // IP Tag `RoutingPreference` requires multiple `zones` and `Standard` SKU to be set
      idle_timeout_in_minutes = optional(number, 4)   // The value can be set between 4 and 30 minutes

      ddos_protection = optional(object({
        mode    = string // Possible values are `Disabled`, `Enabled`, and `VirtualNetworkInherited`. Defaults to `VirtualNetworkInherited`.
        plan_id = string // `ddos_protection_plan_id` can only be set when `ddos_protection_mode` is `Enabled`
      }))
    }))

    backend_name = string
    vm_backend_addresses = optional(list(object({ // Only useful for VMs
      name               = string
      virtual_network_id = string
      ip_address         = string
    })), [])

    lb_rules = optional(list(object({
      name        = optional(string)
      destination = list(string)

      disable_outbound_snat   = optional(bool, false)
      floating_ip_enabled     = optional(bool, false) // Required to configure a SQL AlwaysOn Availability Group.
      tcp_reset_enabled       = optional(bool, false)
      idle_timeout_in_minutes = optional(number, 4) // between 4 and 30 minutes

      probe = optional(object({
        destination         = list(string) // Format as [protocol, port, request_path]
        interval_in_seconds = optional(number, 5)
        number_of_probes    = optional(number, 2)
      }))
    })), [])

    nat_rules = optional(list(object({
      name        = optional(string)
      vm_type     = optional(string, "vmss") // vm, vmss
      destination = list(string)

      floating_ip_enabled     = optional(bool, false) // Required to configure a SQL AlwaysOn Availability Group.
      tcp_reset_enabled       = optional(bool, false)
      idle_timeout_in_minutes = optional(number, 4) // between 4 and 30 minutes
    })), [])
  }))
}
