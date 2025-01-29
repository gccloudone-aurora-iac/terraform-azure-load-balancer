output "public_ip_addresses" {
  value = { for frontend_name, value in local.public_ips : frontend_name => azurerm_lb_backend_address_pool.this[frontend_name].id }
}

output "load_balancer_id" {
  value = azurerm_lb.this.id
}

output "backend_address_pool_id" {
  value = { for frontend_name, value in var.frontend : frontend_name => azurerm_lb_backend_address_pool.this[frontend_name].id }
}

output "nat_rule_ids" {
  value = {
    for frontend_name, value in var.frontend : frontend_name => {
      for index, rule_value in local.nat_rules : rule_value.name => azurerm_lb_nat_rule.this[rule_value.name].id
    }
  }
}

output "nat_pool_rule_ids" {
  value = {
    for frontend_name, value in var.frontend : frontend_name => {
      for index, rule_value in local.nat_pool_rules : rule_value.name => azurerm_lb_nat_pool.this[rule_value.name].id
    }
  }
}

output "lb_rules" {
  value = {
    for frontend_name, value in var.frontend : frontend_name => {
      for index, rule_value in local.lb_rules : rule_value.name => {
        lb_id    = azurerm_lb_rule.this[rule_value.name].id
        probe_id = azurerm_lb_probe.this[rule_value.name].id
      } if rule_value.frontend_name == frontend_name
    }
  }
}
