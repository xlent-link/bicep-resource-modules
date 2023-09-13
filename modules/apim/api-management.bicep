// ----------------------------------------------------------------------------
// API MANAGEMENT
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The name of the apim instance')
param name string

param publisherName string
param publisherEmail string
param apiMgmtSku string
param apiMgmtCapacity int

param loggerApplicationInsightsResourceId string
param loggerApplicationInsightsInstrumentationKey string

@description('A list of named host keys, used for accessing sites. Objects with "name" and "key"')
param hostKeys array = []

@description('A list apim products. Objects with "name", "displayName", "approvalRequired", "description" and "terms"')
param products array = []


resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' = {
  name: name
  location: location
  sku: {
    capacity: apiMgmtCapacity
    name: apiMgmtSku
  }
  properties: {
    virtualNetworkType: 'None'
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource loggerCredential 'Microsoft.ApiManagement/service/namedValues@2022-09-01-preview' = {
  name: 'application-insights-instrumentation-key'
  parent: apim
  properties: {
    displayName: 'application-insights-instrumentation-key'
    value: loggerApplicationInsightsInstrumentationKey
    secret: true
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2022-08-01' = {
  name: 'apim-logger'
  parent: apim
  properties: {
    description: ''
    isBuffered: true
    loggerType: 'applicationInsights'
    resourceId: loggerApplicationInsightsResourceId
    credentials: {
      instrumentationKey: '{{${loggerCredential.name}}}'
    }
  }
}

resource hostKeyNamedValues 'Microsoft.ApiManagement/service/namedValues@2022-09-01-preview' = [for entry in hostKeys: {
  name: entry.name
  parent: apim
  properties: {
    displayName: entry.name
    value: entry.key
    secret: true
  }
}]


resource bapiProducts 'Microsoft.ApiManagement/service/products@2022-09-01-preview' = [for entry in products: {
  name: entry.name
  parent: apim
  properties: {
    approvalRequired: entry.approvalRequired
    description: entry.description
    displayName: entry.name
    state: 'published'
    subscriptionRequired: true
    subscriptionsLimit: null
    terms: entry.terms
  }
}]

// ----------------------------------------------------------------------------
// OUTPUT
// ----------------------------------------------------------------------------

output apimName string = apim.name
