// ----------------------------------------------------------------------------
// function-app-subscription-scope
//
// Creates resources need for the function app with health checker
// This is for when function app and health checker is in different resource groups and the scope is subscription
// ----------------------------------------------------------------------------


param location string
@allowed([
  'dev' // Dev environment
  'test' // Test environment
  'prod' // Production environment
])

// Common things that should be the same for all function app resources
param environment string

param commonResourceGroupName string

param prefix string = 'certego'

param apimName string

param functionAppHostKey string

param commonApplicationInsightsInstrumentationKey string

param commonApplicationInsightsResourceId string

param commonAlertActionGroupId string

// Specific for the current resource group and scope

@description('The name of the resourcegroup where the function app should be located')

param currentResourceGroupName string

@description('The name of the resource')

param currentResourceName string

targetScope = 'subscription'


// ----------------------------------------------------------------------------
// The function app
// ----------------------------------------------------------------------------
@description('Create resources for the component')
module functionApp 'function-app.bicep' = {
  name: '${deployment().name}-function-app'
  scope: resourceGroup(currentResourceGroupName)
  params: {
    location: location
    environment: environment
    name: currentResourceName
    storageAccountName: '${environment}${currentResourceName}${substring(uniqueString('${currentResourceName}${environment}'), 0, 8)}' // Globally unique and max 23 lower-case letters. Environment can be 4 char!!
    commonResourceGroupName: commonResourceGroupName
    prefix: prefix
    // sqlServerName: common.outputs.sqlServerName
    // sqlDatabaseName: 'ticket-${environment}'
    apimName: apimName
    apimHostKey: functionAppHostKey
    applicationInsightsInstrumentationKey: commonApplicationInsightsInstrumentationKey
  }
}

// ----------------------------------------------------------------------------
// HEALTH CHECKING 
// ----------------------------------------------------------------------------
@description('Add health checking.')
module ingridMarieHealthChecking 'site-health-checking.bicep' = {
  name: '${deployment().name}-health-checking'
  scope: resourceGroup(commonResourceGroupName)
  params: {
    location: location
    name: '${currentResourceName}-${environment}-health-check'
    applicationInsightsResourceId: commonApplicationInsightsResourceId //Point on the output from common
    url: 'https://${functionApp.outputs.functionAppDefaultHostName}/api/health'
    alertActionGroupId: commonAlertActionGroupId
  }
}

output functionAppName string = functionApp.outputs.functionAppName
