// ----------------------------------------------------------------------------
// COMMON; common resources, not specific to any adapter
//
// Note: The service principal for the ADO service connection must be owner
//       of the Key Vault.
// Note: The service principal for the ADO service connection must be owner
//       of the file storage storage account
// ----------------------------------------------------------------------------

param location string
param environment string

@description('If set, used to prefix resource names')
param prefix string = ''

param adminGroupObjectName string
param adminGroupObjectId string

param alertEmail string


// Setup
var createDatabases = (adminGroupObjectName != '') ? true : false
var dashedPrefix = endsWith(prefix, '-') ? prefix : '${prefix}-'


// ----------------------------------------------------------------------------
// APPLICATION INSIGHTS for telemetry
// ----------------------------------------------------------------------------
module applicationInsights '../modules/application-insights/ai-for-environment.bicep' = {
  name: '${deployment().name}-common-application-insights'
  params: {
    environment: environment
    location: location
    prefix: prefix
  }
}

// ----------------------------------------------------------------------------
// APPLICATION INSIGHTS for logging
// ----------------------------------------------------------------------------
module aiMonitor '../modules/application-insights/ai-logging-monitor.bicep' = {
  name: '${deployment().name}-monitor-application-insights'
  params: {
    environment: environment
    location: location
    prefix: prefix
    alertEmail: alertEmail
    actionGroupName: 'Alerts'
    emailReceiverName: 'Teams channel'
  }
}

// ----------------------------------------------------------------------------
// PRE-DEFINED LOG QUERIES
// ----------------------------------------------------------------------------
module queryPack '../modules/application-insights/query-pack.bicep' = {
  name: '${deployment().name}-query-pack'
  params: {
    location: location
    environment: environment
    queries: [
      {
        id: 'd39889e0-17a9-4358-ace4-c89b203832af'
        name: 'All monitor logs, desc'
        query: '''traces
| project timestamp, message,
    level = case(severityLevel == 0, "verbose", severityLevel == 2, "warning",  severityLevel == 3, "error", severityLevel == 4, "critical", "information"),
    app = customDimensions.Application,
    correlationId = customDimensions.CorrelationId,
    category = customDimensions.Category,
    customDimensions
| order by timestamp desc
'''
      }
    ]
  }
}

// ----------------------------------------------------------------------------
// FILE SERVER
// ----------------------------------------------------------------------------
module fileServer '../modules/storage/file-server.bicep' = {
  name: '${deployment().name}-file-server'
  params: {
    location: location
    name: 'files${environment}${uniqueString(resourceGroup().id)}'
    adminGroupObjectId: adminGroupObjectId
  }
}

// ----------------------------------------------------------------------------
// API MANAGEMENT
// ----------------------------------------------------------------------------
var apiMgmtSku = (environment == 'prod') ? 'Basic' : 'Developer'
var apiMgmtCapacity = (environment == 'prod') ? 0 : 1 // 0 is Consumption
var apiMgmtName = '${dashedPrefix}${environment}-api-mgmt'

var functionAppHostKey = guid(apiMgmtName)

module apim '../modules/apim/api-management.bicep' = {
  name: '${deployment().name}-api-management'
  params: {
    location: location
    name: apiMgmtName
    apiMgmtSku: apiMgmtSku
    apiMgmtCapacity: apiMgmtCapacity
    loggerApplicationInsightsInstrumentationKey: applicationInsights.outputs.applicationInsightsInstrumentationKey
    loggerApplicationInsightsResourceId: applicationInsights.outputs.applicationInsightsResourceId
    publisherName: 'Logent'
    publisherEmail: 'development@logent.se'
    hostKeys: [
      {
        name: 'function-apps-host-key'
        key: functionAppHostKey
      }
    ]
    products: [
      {
        name: 'business-api-product'
        displayName: 'Logent business API'
        description: 'Access to the Logent business API'
        approvalRequired: true
        terms: ''
      }
    ]
  }
}

// ----------------------------------------------------------------------------
// API: transport-management
// ----------------------------------------------------------------------------
@description('Create transport management api')
module transportMgmt 'open-api/transport-management/main.bicep' = {
  name: '${deployment().name}-tm-api'
  params: {
    apimName: apiMgmtName
  }
}

// ----------------------------------------------------------------------------
// SQL SERVER
// ----------------------------------------------------------------------------
module sqlServer '../modules/sql/sql-server.bicep' = {
  name: '${deployment().name}-sql-server'
  params: {
    location: location
    name: '${dashedPrefix}${environment}-sql-server'
    administratorLoginPassword: guid(environment)
    dbAdminGroupName: adminGroupObjectName
    dbAdminGroupObjectId: adminGroupObjectId
  }
}

// ◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥◤◢◣◥
// OUTPUT
// • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • •

output apimName string = apim.name
output functionAppHostKey string = functionAppHostKey
output applicationInsightsResourceId string = applicationInsights.outputs.applicationInsightsResourceId
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.applicationInsightsInstrumentationKey
output alertActionGroupId string = aiMonitor.outputs.alertActionGroupId
output sqlServerName string = createDatabases ? sqlServer.name : ''
