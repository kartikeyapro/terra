# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.38.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "35296e0e-8b82-4eb3-b588-3fadd6a56c09"
  client_id = "5455fade-cbf5-4b75-93d9-030479c0eee9"
  client_secret = "A9w8Q~E5eaBhA2rxlUPvf~eqClEyGHjd_7tZGc~t"
  tenant_id = "885b5db6-1597-4cc1-afe6-a795a33d2de5"
}

resource "azurerm_resource_group" "KS-DEV" {
  name     = var.rg1
  location = "Central India"
}
resource "azurerm_virtual_network" "KS-VNET" {
  name = var.vnet
  resource_group_name = azurerm_resource_group.KS-DEV.name
  location           = azurerm_resource_group.KS-DEV.location
  address_space       = ["10.10.0.0/16"]
}
resource "azurerm_subnet" "KS-DEV-SUB1" {
  name                 = "ks-dev-sub1"
  resource_group_name  = azurerm_resource_group.KS-DEV.name
  virtual_network_name = azurerm_virtual_network.KS-VNET.name
  address_prefixes     = ["10.10.1.0/24"]

}
resource "azurerm_subnet" "KS-DEV-SUB2" {
  name                 = "ks-dev-sub2"
  resource_group_name  = azurerm_resource_group.KS-DEV.name
  virtual_network_name = azurerm_virtual_network.KS-VNET.name
  address_prefixes     = ["10.10.2.0/24"]

}
resource "azurerm_subnet" "KS-DEV-SUB3" {
  name                 = "ks-dev-sub3"
  resource_group_name  = azurerm_resource_group.KS-DEV.name
  virtual_network_name = azurerm_virtual_network.KS-VNET.name
  address_prefixes     = ["10.10.3.0/24"]
}

resource "azurerm_network_security_group" "KS-DEV-NSG" {
  name                = "nsg1"
  location            = azurerm_resource_group.KS-DEV.location
  resource_group_name = azurerm_resource_group.KS-DEV.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  
  tags = {
    environment = "KS-DEV"
  }
}
resource "azurerm_public_ip" "KS-PIP" {
  name                = "PIP1"
  resource_group_name = azurerm_resource_group.KS-DEV.name
  location            = azurerm_resource_group.KS-DEV.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "KS-NIC" {
  name                = "NIC1"
  location            = azurerm_resource_group.KS-DEV.location
  resource_group_name = azurerm_resource_group.KS-DEV.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.KS-DEV-SUB3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.KS-PIP.id
  }
}

resource "azurerm_subnet_network_security_group_association" "KS-NSG" {
  subnet_id                 = azurerm_subnet.KS-DEV-SUB3.id
  network_security_group_id = azurerm_network_security_group.KS-DEV-NSG.id
}

resource "azurerm_virtual_machine" "KSVM1" {
  name                  = "vm"
  location              = azurerm_resource_group.KS-DEV.location
  resource_group_name   = azurerm_resource_group.KS-DEV.name
  network_interface_ids = [azurerm_network_interface.KS-NIC.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_public_ip" "KS-PIP2" {
  name                = "PIP2"
  resource_group_name = azurerm_resource_group.KS-DEV.name
  location            = azurerm_resource_group.KS-DEV.location
  allocation_method   = "Static"

}
resource "azurerm_network_interface" "KS-NIC2" {
  name                = "NIC2"
  location            = azurerm_resource_group.KS-DEV.location
  resource_group_name = azurerm_resource_group.KS-DEV.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.KS-DEV-SUB3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.KS-PIP2.id
  }
}
resource "azurerm_windows_virtual_machine" "win" {
  name                = "win2016"
  resource_group_name = azurerm_resource_group.KS-DEV.name
  location            = azurerm_resource_group.KS-DEV.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.KS-NIC2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}



output "public_ip_address" {
  value = "${azurerm_public_ip.KS-PIP2.*.ip_address}"
}