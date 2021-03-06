locals {
  env       = (var.env == "aat") ? "stg" : (var.env == "sandbox") ? "sbox" : "${(var.env == "perftest") ? "test" : "${var.env}"}"
  apim_name = "${var.department}-api-mgmt-${local.env}"
  apim_rg   = var.department == "sds" ? "ss-${local.env}-network-rg" : var.env == "sbox" || var.env == "perftest" || var.env == "aat" || var.env == "ithc" ? "cft-${var.env}-network-rg" : "aks-infra-${var.env}-rg"
}

resource "azurerm_api_management_product" "apim_product" {
  product_id            = "${var.product}-product-${local.env}"
  resource_group_name   = local.apim_rg
  api_management_name   = local.apim_name
  display_name          = "${var.product}-api-${local.env}-product"
  subscription_required = var.product_subscription_required
  approval_required     = var.product_approval_required
  published             = var.product_published
  description           = var.product_discription != "" ? var.product_discription : "This is the product for ${var.product}"
}

resource "azurerm_api_management_product_policy" "apim_product_policy" {
  count               = var.product_policy != "" ? 1 : 0
  product_id          = azurerm_api_management_product.apim_product.product_id
  api_management_name = azurerm_api_management_product.apim_product.api_management_name
  resource_group_name = azurerm_api_management_product.apim_product.resource_group_name

  xml_content = var.product_policy

}

resource "random_password" "user_password" {
  length      = 20
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
  special     = true
}
resource "azurerm_api_management_user" "apim_user" {
  count               = var.user_id == "" ? 0 : 1
  api_management_name = local.apim_name
  resource_group_name = local.apim_rg
  user_id             = var.user_id
  first_name          = "${var.product} User"
  last_name           = "TF Gen User"
  email               = "${var.product}@hmcts.${local.env}.null"
  state               = "active"
  password            = var.user_has_password ? random_password.user_password.result : null
}

resource "azurerm_api_management_subscription" "apim_subscription" {
  api_management_name = local.apim_name
  resource_group_name = local.apim_rg
  user_id             = var.user_id == "" ? null : azurerm_api_management_user.apim_user[0].id
  product_id          = azurerm_api_management_product.apim_product.id
  display_name        = "${var.product} Subscription"
  state               = "active"
  allow_tracing       = var.env == "sbox" || var.env == "dev" || var.env == "test" ? true : false
}

