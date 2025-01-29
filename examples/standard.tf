#####################
### Prerequisites ###
#####################

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = "lb-module-example-rg"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "this" {
  name                = "example-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
  }

  tags = {
    environment = "Production"
  }
}

############################
### Load Balancer Module ###
############################

module "load_balancer" {
  source = "../"

  azure_resource_attributes = {
    project     = "aur"
    environment = "dev"
    location    = azurerm_resource_group.this.location
    instance    = 0
  }

  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  type                = "public"

  frontend = {
    test = {
      backend_name = "test"
      vm_backend_addresses = [
        {
          name               = "address1"
          virtual_network_id = azurerm_virtual_network.this.id
          ip_address         = "10.0.1.1"
        }
      ]

      lb_rules = [
        {
          destination = ["Tcp", "8080", "8080"]

          probe = {
            destination = ["Tcp", "8080"]
          }
        },
        {
          destination = ["Tcp", "808", "808"]

          probe = {
            destination = ["Tcp", "808"]
          }
        },
      ]

      nat_rules = [
        {
          vm_type     = "vmss"
          destination = ["Tcp", "9091-9093", "8091"]
        },
        {
          vm_type     = "vm"
          destination = ["Tcp", "8888-8889", "9099"]
        }
      ]
    }
  }

  depends_on = [azurerm_resource_group.this]
}

output "lb_rules" {
  value = module.load_balancer.lb_rules
}

output "backend_address_pool_id" {
  value = module.load_balancer.backend_address_pool_id
}

output "nat_pool_rule_ids" {
  value = module.load_balancer.nat_pool_rule_ids
}

output "nat_rule_ids" {
  value = module.load_balancer.nat_rule_ids
}
