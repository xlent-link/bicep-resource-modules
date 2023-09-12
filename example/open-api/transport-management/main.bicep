// ----------------------------------------------------------------------------
// API deployment
// ----------------------------------------------------------------------------

param apimName string

// ----------------------------------------------------------------------------
// TRANSPORT MANAGEMENT API
// ----------------------------------------------------------------------------
var openapiYaml = loadTextContent('transport-management-v1.yaml')

var tmApiName = 'transport-management-api'

module tmApi '../../../modules/apim/api-from-yaml.bicep' = {
  name: '${deployment().name}-transport-management-api'
  params: {
    apimName: apimName
    name: tmApiName
    displayName: 'Transport management API'
    path: 'transport-management/v1'
    openapiYaml: openapiYaml
    products: [
      {
        productName: 'business-api-product'
        apiName: tmApiName
      }
    ]
  }
}
