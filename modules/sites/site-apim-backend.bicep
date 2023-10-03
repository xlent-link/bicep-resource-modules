// ----------------------------------------------------------------------------
// APIM BACKEND for an api
// ----------------------------------------------------------------------------

@description('The name of the site, e.g. a function app')
param siteName string

@description('The full name of the site, e.g. a function app')
param siteAppName string

@description('The name of the API Management instance to create a backend for')
param apimName string

@description('The name of the API that we are creating a backend for. Must exist already.')
param apiName string

@description('The path of API, starting with slash (/). Do not include the host.')
param urlPath string

@description('E.g. the function app id; functionApp.id')
param resourceId string


@description('If the function app is not located in the common resource group, then it is necessary to refer to that group here')
param commonResourceGroupName string

// ----------------------------------------------------------------------------
// APIM BACKEND
// ----------------------------------------------------------------------------

resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
  scope: length(commonResourceGroupName) != 0 ? resourceGroup(commonResourceGroupName) : resourceGroup()
}

resource apiBackend 'Microsoft.ApiManagement/service/backends@2022-08-01' = {
  name: '${siteName}-${apiName}'
  parent: apim
  properties: {
    url: 'https://${siteAppName}.azurewebsites.net${urlPath}'
    resourceId: '${az.environment().resourceManager}${substring(resourceId, 1)}'
    credentials: {
      header: {
        'x-functions-key': [
          '{{function-apps-host-key}}'
        ]
      }
    }
    protocol: 'http'
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2022-09-01-preview' existing = {
  parent: apim
  name: apiName
}

resource backendPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  scope: length(commonResourceGroupName) != 0 ? resourceGroup(commonResourceGroupName) : resourceGroup()

  name: 'policy'
  parent: api
  properties: {
    format: 'xml'
    value: '<policies><inbound><base /><set-backend-service backend-id="${apiBackend.name}" /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
  }
}
