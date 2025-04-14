resource "azurerm_public_ip" "this" {
  for_each = local.public_ips

  name                = coalesce(try(each.value.public_ip_address.name, null), "${module.azure_resource_names.public_ip_address_name}-lb")
  resource_group_name = var.resource_group_name
  location            = var.azure_resource_attributes.location
  public_ip_prefix_id = try(each.value.public_ip_address.public_ip_prefix_id, null)

  sku               = var.sku
  sku_tier          = var.sku_tier
  allocation_method = each.value.ip_address_allocation
  ip_version        = each.value.ip_address_version

  idle_timeout_in_minutes = try(each.value.public_ip_address.idle_timeout_in_minutes, null)
  ip_tags                 = try(each.value.public_ip_address.ip_tags, null)
  domain_name_label       = try(each.value.public_ip_address.domain_name_label, null)
  reverse_fqdn            = try(each.value.public_ip_address.reverse_fqdn, null)

  ddos_protection_mode    = try(each.value.public_ip_address.ddos_protection.mode, null)
  ddos_protection_plan_id = try(each.value.public_ip_address.ddos_protection.plan_id, null)

  zones     = var.availability_zones
  edge_zone = var.edge_zone

  tags = local.tags
}

#####################
### Load Balancer ###
#####################

resource "azurerm_lb" "this" {
  name                = module.azure_resource_names.load_balancer_name
  resource_group_name = var.resource_group_name
  location            = var.azure_resource_attributes.location

  sku      = var.sku
  sku_tier = var.sku_tier

  dynamic "frontend_ip_configuration" {
    for_each = var.frontend

    content {
      name = frontend_ip_configuration.key

      subnet_id                     = frontend_ip_configuration.value.subnet_id
      private_ip_address_allocation = var.type == "private" ? frontend_ip_configuration.value.ip_address_allocation : null
      private_ip_address_version    = var.type == "private" ? frontend_ip_configuration.value.ip_address_version : null
      private_ip_address            = frontend_ip_configuration.value.private_ip_address

      public_ip_address_id = try(azurerm_public_ip.this[frontend_ip_configuration.key].id, null)
      public_ip_prefix_id  = frontend_ip_configuration.value.public_ip_prefix_id

      zones = var.availability_zones
    }
  }

  edge_zone = var.edge_zone

  tags = local.tags
}

# #########################
# ### Inbound NAT Rules ###
# #########################

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = var.frontend

  loadbalancer_id = azurerm_lb.this.id
  name            = each.value.backend_name
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  for_each = { for index, value in local.backend_ips : value.frontend_name => value }

  name                    = each.value.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this[each.value.frontend_name].id

  virtual_network_id = each.value.virtual_network_id
  ip_address         = each.value.ip_address
}

# #########################
# ### Inbound NAT Rules ###
# #########################

# For VMs
resource "azurerm_lb_nat_rule" "this" {
  for_each = { for index, value in local.nat_rules : value.name => value }

  name                = each.key
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.this.id

  protocol            = each.value.protocol
  frontend_port       = each.value.frontend_port
  frontend_port_start = each.value.frontend_port_start
  frontend_port_end   = each.value.frontend_port_end
  backend_port        = each.value.backend_port

  frontend_ip_configuration_name = each.value.frontend_name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.this[each.value.frontend_name].id

  enable_floating_ip      = each.value.floating_ip_enabled
  enable_tcp_reset        = each.value.tcp_reset_enabled
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}

# # For VM Scale Sets
resource "azurerm_lb_nat_pool" "this" {
  for_each = { for index, value in local.nat_pool_rules : value.name => value }

  name                = each.key
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.this.id

  protocol                       = each.value.protocol
  frontend_port_start            = each.value.frontend_port_start
  frontend_port_end              = each.value.frontend_port_end
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_name

  floating_ip_enabled     = each.value.floating_ip_enabled
  tcp_reset_enabled       = each.value.tcp_reset_enabled
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}

############################
### Load Balancing Rules ###
############################

resource "azurerm_lb_probe" "this" {
  for_each = { for index, value in local.lb_rules : value.name => value }

  name            = lower("${each.value.backend_name}-${each.value.probe.protocol}-${each.value.probe.port}")
  loadbalancer_id = azurerm_lb.this.id

  protocol     = each.value.probe.protocol
  port         = each.value.probe.port
  request_path = each.value.probe.request_path

  interval_in_seconds = each.value.probe.interval_in_seconds
  number_of_probes    = each.value.probe.number_of_probes
}

resource "azurerm_lb_rule" "this" {
  for_each = { for index, value in local.lb_rules : value.name => value }

  name            = each.key
  loadbalancer_id = azurerm_lb.this.id

  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_name

  backend_address_pool_ids = [azurerm_lb_backend_address_pool.this[each.value.frontend_name].id]
  probe_id                 = azurerm_lb_probe.this[each.key].id

  disable_outbound_snat   = each.value.disable_outbound_snat
  enable_floating_ip      = each.value.floating_ip_enabled
  enable_tcp_reset        = each.value.tcp_reset_enabled
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}
