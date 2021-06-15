terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.62.0"
    }
  }
  backend "azurerm" {
    key                  = "azure-devops-tf-test.tfstate"
  }
}

provider "azurerm" {
  features {}
}


resource "azuredevops_project" "project" {
  name               = var.project
  visibility         = "public"
  version_control    = "Git"
  work_item_template = "Agile"

  features = {
    "testplans" = "disabled"
    "artifacts" = "disabled"
  }
}

data "azurerm_client_config" "current" {
}
resource "azurerm_resource_group" "rg" {
  name     = "azure-devops-tf-test-rg"
  location = "East US"
}

resource "azurerm_key_vault" "keyvault" {
  name                        = "kv-azure-devops-tf-test"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "backup",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
      "delete",
    ]
    certificate_permissions = [
    ]
    key_permissions = [
    ]
  }

}

resource "azurerm_key_vault_secret" "secret" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "supersecret"
  value        = "this is supersecret"
}

resource "azuredevops_serviceendpoint_azurerm" "endpointazure" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "ARM_SUBSCRIPTION"
  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = var.subscription_name
  credentials  {
      serviceprincipalid = data.azurerm_client_config.current.object_id
      serviceprincipalkey = var.serviceprincipalkey 
  }
}

resource "azuredevops_resource_authorization" "auth" {
  project_id  = azuredevops_project.project.id
  resource_id = azuredevops_serviceendpoint_azurerm.endpointazure.id
  authorized  = true 
}

resource "azuredevops_variable_group" "kvvargroup" {
  project_id   = azuredevops_project.project.id
  name         = azurerm_key_vault.keyvault.name
  description  = "tf controlled variable group integration"
  allow_access = true

  key_vault {
    name                = azurerm_key_vault.keyvault.name
    service_endpoint_id = azuredevops_serviceendpoint_azurerm.endpointazure.id
  }

  variable {
    name    = "supersecret"
  }
}

