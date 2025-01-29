locals {
  public_ips = {
    for name, value in var.frontend :
    name => value
    if var.type == "public" && (value.public_ip_address_id == null && value.public_ip_prefix_id == null)
  }

  backend_ips = flatten([
    for key, value in var.frontend : [
      for backend_address in value.vm_backend_addresses : {
        frontend_name      = key
        name               = backend_address.name
        virtual_network_id = backend_address.virtual_network_id
        ip_address         = backend_address.ip_address
      }
    ]
  ])

  nat_rules = flatten([
    for key, value in var.frontend : [
      for rule in value.nat_rules : {
        name          = coalesce(rule.name, lower("${var.type}-${rule.destination[1]}-to-${value.backend_name}-${rule.destination[2]}-${rule.destination[0]}"))
        frontend_name = key
        backend_name  = value.backend_name

        protocol            = rule.destination[0]
        frontend_port       = length(split("-", rule.destination[1])) == 2 ? null : rule.destination[1]
        frontend_port_start = length(split("-", rule.destination[1])) == 2 ? split("-", trimspace(rule.destination[1]))[0] : null
        frontend_port_end   = length(split("-", rule.destination[1])) == 2 ? split("-", trimspace(rule.destination[1]))[1] : null
        backend_port        = rule.destination[2]

        floating_ip_enabled     = rule.floating_ip_enabled
        tcp_reset_enabled       = rule.tcp_reset_enabled
        idle_timeout_in_minutes = rule.idle_timeout_in_minutes
      } if rule.vm_type == "vm"
    ]
  ])

  nat_pool_rules = flatten([
    for key, value in var.frontend : [
      for rule in value.nat_rules : {
        name          = coalesce(rule.name, lower("${var.type}-${split("-", trimspace(rule.destination[1]))[0]}-${split("-", trimspace(rule.destination[1]))[1]}-to-${value.backend_name}-${rule.destination[2]}-${rule.destination[0]}"))
        frontend_name = key
        backend_name  = value.backend_name

        protocol            = rule.destination[0]
        frontend_port_start = split("-", trimspace(rule.destination[1]))[0]
        frontend_port_end   = split("-", trimspace(rule.destination[1]))[1]
        backend_port        = rule.destination[2]

        floating_ip_enabled     = rule.floating_ip_enabled
        tcp_reset_enabled       = rule.tcp_reset_enabled
        idle_timeout_in_minutes = rule.idle_timeout_in_minutes
      } if rule.vm_type == "vmss"
    ]
  ])

  // name is {type}-{frontend_port}-to-{backend_name}-{backend_port}-{protocol}
  lb_rules = flatten([
    for key, value in var.frontend : [
      for rule in value.lb_rules : {
        name          = coalesce(rule.name, lower("${var.type}-${rule.destination[1]}-to-${value.backend_name}-${rule.destination[2]}-${rule.destination[0]}"))
        frontend_name = key
        backend_name  = value.backend_name

        protocol      = rule.destination[0]
        frontend_port = rule.destination[1]
        backend_port  = rule.destination[2]

        disable_outbound_snat   = rule.disable_outbound_snat
        floating_ip_enabled     = rule.floating_ip_enabled
        tcp_reset_enabled       = rule.tcp_reset_enabled
        idle_timeout_in_minutes = rule.idle_timeout_in_minutes

        probe = {
          protocol     = rule.probe.destination[0]
          port         = rule.probe.destination[1]
          request_path = try(rule.probe.destination[2], null)

          interval_in_seconds = rule.probe.interval_in_seconds
          number_of_probes    = rule.probe.number_of_probes
        }
      }
    ]
  ])

  tags = merge(
    var.tags,
    {
      ModuleName    = "terraform-azure-load-balancer",
      ModuleVersion = "v1.0.0",
    }
  )
}
