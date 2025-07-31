provider "azurerm" {
  features {}
}

# Define tags (for the policy)
locals {
  tags = {
    environment = "${var.environment}"
    project     = "${var.project}"
    owner       = "${var.owner}"
  }
}

# the resource group
data "azurerm_resource_group" "main" {
  name = "${var.group_name}"
}

#the vn (had errors for the address_space value so added it here, not using var file)
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

#the subnet (had errors for the address_prefixes value so added it here, not using var file)
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

# to control the network traffic
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}
####new rules
#  Rule priority 110/115/120/130/ (uniq)
#1
resource "azurerm_network_security_rule" "Allow_Traffic_Within_VNET" {
  name                        = "AllowTrafficWithinVNET"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.10.0.0/16"
  destination_address_prefix  = "10.10.0.0/16"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}
#2
resource "azurerm_network_security_rule" "block_internet" {
  name                        = "BlockAllInternet"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}
#3
resource "azurerm_network_security_rule" "allow_outbound_vnet" {
  name                        = "AllowOutboundWithinVNET"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.10.0.0/16"
  destination_address_prefix  = "10.10.0.0/16"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}
#4
resource "azurerm_network_security_rule" "allow_http_lb" {
  name                        = "AllowHTTPFromLoadBalancer"
  priority                    = 115
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.prefix}-azure-project1"
  tags                = local.tags
}

resource "azurerm_availability_set" "main" {
  name                         = "${var.prefix}-avset"
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  tags                         = local.tags
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                 = "${var.prefix}-lbfrontend"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-backendpool"
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-lbhealth"
  port                = 80
}

resource "azurerm_lb_rule" "main" {
  resource_group_name            = data.azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "${var.prefix}-lbrule"
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-lbfrontend"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
}

data "azurerm_image" "packer-image" {
  name                = var.image
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.number_of_vms
  name                            = "${var.prefix}-vm-${count.index}"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.main.name
  network_interface_ids           = ["${element(azurerm_network_interface.main.*.id, count.index)}"]
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  availability_set_id             = azurerm_availability_set.main.id
  tags                            = local.tags
  source_image_id                 = data.azurerm_image.packer-image.id

  os_disk {
    name                 = "${var.prefix}-osdisk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

resource "azurerm_managed_disk" "main" {
  count                = var.number_of_vms
  name                 = "${var.prefix}-datadisk-${count.index}"
  location             = var.location
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
  tags                 = local.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = var.number_of_vms
  managed_disk_id    = element(azurerm_managed_disk.main.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.main.*.id, count.index)
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_network_interface" "main" {
  count               = var.number_of_vms
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags

  ip_configuration {
    name                          = "${var.prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.number_of_vms
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   = "${var.prefix}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.number_of_vms
  network_interface_id      = element(azurerm_network_interface.main.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.main.id
}
