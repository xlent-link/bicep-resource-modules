// ----------------------------------------------------------------------------
// FUNCTION APP
//
// Creates resources need for the function app.
// Opt-in for key vault, database, APIM backend, etc
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The customer environment, like "test" or "prod"')
param environment string

@description('If set, used to prefix resource names')
param prefix string = ''

@description('The name of the component. Use kebab-casing.')
param name string

@description('The name of the storage account to use for the function app')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('The application insights instance to use for telemetry')
param applicationInsightsInstrumentationKey string

@description('If set, used to setup a Standard test web on an application insights resource')
param healthCheckApplicationInsightsResourceId string = ''
@description('If health checking is used, this is the action group that is used for alerts')
param alertActionGroupId string = ''

@description('If using a database, the sql server to maybe create a database in')
param sqlServerName string = ''
@description('If using a database, this is the name of the database')
param sqlDatabaseName string = ''
param databaseSkuName string = 'Basic'
param databaseSkuTier string = 'Basic'

@description('Tells if the function app should have its own key vault')
param useKeyVault bool = true
@description('When creating a key vault, you can set admin access to this AD group')
param keyVaultGroupObjectId string = ''

@description('If set, the name of the API Management instance that this function app will be a backend of')
param apimName string = ''
@description('If using APIM, the host key used by APIM for accessing the functions')
@secure()
param apimHostKey string = ''

@description('A list of apis that this function app is the backend for. List of objects with "apiName" and "path"')
param apimBackends array = []

// Setup
var dashedPrefix = endsWith(prefix, '-') ? prefix : '${prefix}-'
var functionAppPlanName = '${dashedPrefix}${environment}-${name}-app-plan'
var functionAppName = '${dashedPrefix}${environment}-${name}'

// ----------------------------------------------------------------------------
// STORAGE ACCOUNT
// ----------------------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// ----------------------------------------------------------------------------
// FUNCTION APP; dynamic plan and site
// ----------------------------------------------------------------------------
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: functionAppPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = if (length(apimName) != 0) {
  name: apimName
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      // Intentionally no 'appSettings'. See merge below
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      apiManagementConfig: {
        id: apim.?id
      }
    }
    httpsOnly: true
    //keyVaultReferenceIdentity: keyVaultReaderIdentityId
  }
}

var functionAppAppSettings = {
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value}'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value}'
  WEBSITE_CONTENTSHARE: toLower(functionAppName)
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsightsInstrumentationKey
}

@description('Merge app settings. If set by siteConfig on function-app, that will erase any other app setting.')
module appSettings 'site-appsettings.bicep' = {
  name: '${deployment().name}-appsettings'
  params: {
    siteName: functionApp.name
    // Get the current appsettings
    currentAppSettings: list(resourceId('Microsoft.Web/sites/config', functionApp.name, 'appsettings'), '2022-03-01').properties
    appSettings: functionAppAppSettings
  }
}

// Use a HOST key for access HttpTrigger(AuthorizationLevel.Function, ...
// NOTE! This can fail sometimes; just re-run
var keyName = 'apim-key'
#disable-next-line BCP081
resource default_keyName 'Microsoft.Web/sites/host/functionKeys@2018-11-01' = if (length(apimHostKey) != 0) { // This is an undocumented template
  name: '${functionAppName}/default/${keyName}'
  properties: {
    name: keyName
    value: apimHostKey
  }
}

// ----------------------------------------------------------------------------
// HEALTH CHECKING
// ----------------------------------------------------------------------------
@description('Add health checking.')
module healthChecking 'site-health-checking.bicep' = if (length(healthCheckApplicationInsightsResourceId) != 0) {
  name: '${deployment().name}-health-checking'
  params: {
    location: location
    name: '${name}-health-check'
    applicationInsightsResourceId: healthCheckApplicationInsightsResourceId
    url: 'https://${functionApp.properties.defaultHostName}/health'
    alertActionGroupId: alertActionGroupId
  }
}

// ----------------------------------------------------------------------------
// KEY VAULT
// ----------------------------------------------------------------------------
@description('Add key vault.')
module keyVault 'site-key-vault.bicep' = if (useKeyVault) {
  name: '${deployment().name}-key-vault'
  params: {
    location: location
    name: '${dashedPrefix}${environment}-${name}-keyvault'
    principalId: functionApp.identity.principalId
    keyVaultGroupObjectId: keyVaultGroupObjectId
  }
}

// ----------------------------------------------------------------------------
// APIM BACKEND
// ----------------------------------------------------------------------------

module apiBackends 'site-apim-backend.bicep' = [for entry in apimBackends: if (length(apimName) != 0) {
  name: 'api-backend-${name}-${entry.apiName}'
  params: {
    siteName: name
    siteAppName: functionAppName
    apimName: apimName
    apiName: entry.apiName
    urlPath: entry.path
    resourceId: functionApp.id
  }
}]

// ----------------------------------------------------------------------------
// DATABASE
// ----------------------------------------------------------------------------
module database '../sql/sql-database.bicep' = if (length(sqlDatabaseName) != 0) {
  name: '${deployment().name}-database'
  params: {
    location: location
    sqlServerName: sqlServerName
    databaseName: sqlDatabaseName
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier
  }
}

// Note: If the object id of this System Assigned identity is changed (if removed and added again),
// we need to drop/create database user
