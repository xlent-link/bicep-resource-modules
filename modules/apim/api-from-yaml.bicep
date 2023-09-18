// ----------------------------------------------------------------------------
// API deployment
// ----------------------------------------------------------------------------

@description('The name of the existing apim instance')
param apimName string

@description('The name of api; kebab-case')
param name string

@description('The display name of api')
param displayName string

@description('The path api')
param path string

@description('The yaml that represents the open api specification')
param openapiYaml string

@description('A list of apim products that this api belongs to. Objects with "productName" and "apiName"')
param products array = []


resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
}

resource api 'Microsoft.ApiManagement/service/apis@2022-09-01-preview' = {
  parent: apim
  name: name
  properties: {
    displayName: displayName
    apiType: 'http'
    contact: {
      email: apim.properties.publisherEmail
      name: apim.properties.publisherName
    }
    path: path
    protocols: [
      'https'
    ]
    isCurrent: true
    subscriptionRequired: true
    type: 'http'
    format: 'openapi'
    value: openapiYaml
  }
}

// Add to products
module productsToApi 'api-to-product.bicep' = [for (entry, index) in products: {
  name: '${deployment().name}-${index}'
  params: {
    apimName: apimName
    productName: entry.productName
    apiName: entry.apiName
  }
}]
