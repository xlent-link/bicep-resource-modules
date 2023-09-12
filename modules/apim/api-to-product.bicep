// ----------------------------------------------------------------------------
// ADD API TO PRODUCT
// ----------------------------------------------------------------------------

@description('The name of the existing apim instance')
param apimName string

@description('The name of the product to add the api to')
param productName string

@description('The name of the api to add')
param apiName string


resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
}

resource apiProduct 'Microsoft.ApiManagement/service/products@2022-09-01-preview' existing = {
  name: productName
  parent: apim
}

resource productsApi 'Microsoft.ApiManagement/service/products/apis@2022-09-01-preview' = {
  name: apiName
  parent: apiProduct
}
