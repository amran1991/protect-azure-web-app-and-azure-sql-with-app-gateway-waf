terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 1.2.0, <= 3.75.0"
    }
  }
}

provider "azurerm" {
  features {}
}