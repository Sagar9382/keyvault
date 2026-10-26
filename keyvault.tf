terraform {
    required_providers {
        azurerm ={
            source = "hashicorp/azurerm"
            version = " 5.10.0"
        }
    }
}

provider "azurerm" {
    features{}
}

# 1. Naya Key Vault read karne ke liye DATA block
# (Make sure aapne portal par Vault Access Policy mode se naya KV bana liya hai)
data "azurerm_key_vault" "existing_kv" {
  name                = "practicekey2" # Portal wale naye Key Vault ka naam likhein
  resource_group_name = "lal"                      # Resource group ka naam 'lal' kar diya hai
}

# 2. Key Vault ke andar se Secret read karne ke liye DATA block
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = data.azurerm_key_vault.existing_kv.id
}

# 3. Resource Group (Jiska naam 'lal' hai)
resource "azurerm_resource_group" "rg" {
  name     = "lal"
  location = "eastus"
}

# 4. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "practical-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 5. Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "practical-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 6. Network Interface (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "practical-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 7. Linux Virtual Machine (VM)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "practical-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  disable_password_authentication = false
  
  # Secret value yahan assign ho rahi hai
  admin_password = data.azurerm_key_vault_secret.vm_password.value

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

