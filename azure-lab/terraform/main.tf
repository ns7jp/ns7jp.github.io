# Azure Lab メイン定義
# 構成:
#   - Resource Group
#   - VNet (10.50.0.0/16)
#     - snet-app       (10.50.10.0/24)  Linux VM 用
#     - AzureBastionSubnet (10.50.255.0/27) Bastion 用（名前固定が必須）
#   - NSG: Bastion 経由の SSH のみ許可、Internet からの直接接続は明示拒否
#   - Linux VM (Ubuntu 22.04, Standard_B1s) パブリックIPなし
#   - Bastion (Basic SKU) パブリックIPあり
#
# パブリックIPは Bastion 1個だけにする = 攻撃面を最小化する設計。

# ---- Resource Group --------------------------------------------------------
resource "azurerm_resource_group" "lab" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# ---- 仮想ネットワーク -------------------------------------------------------
resource "azurerm_virtual_network" "lab" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  address_space       = ["10.50.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.50.10.0/24"]
}

# Bastion 用のサブネット名は AzureBastionSubnet 固定。改名するとデプロイ失敗。
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.50.255.0/27"]
}

# ---- NSG （Bastion 経由のみ許可、Internet 直アクセスは明示拒否） ----------
resource "azurerm_network_security_group" "app" {
  name                = "${var.prefix}-app-nsg"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = var.tags

  security_rule {
    name                       = "AllowBastionSSHIn"
    description                = "Bastion サブネットからの SSH のみ許可"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.50.255.0/27"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyInternetIn"
    description                = "Internet からのインバウンドは全面拒否（implicit deny に頼らない）"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# ---- Linux VM -------------------------------------------------------------
resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-vm-nic"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "lab" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_pubkey
  }

  os_disk {
    name                 = "${var.prefix}-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ---- Bastion --------------------------------------------------------------
resource "azurerm_public_ip" "bastion" {
  name                = "${var.prefix}-bastion-pip"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "lab" {
  name                = "${var.prefix}-bastion"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  sku                 = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "primary"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
