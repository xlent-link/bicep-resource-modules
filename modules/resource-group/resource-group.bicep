// ----------------------------------------------------------------------------
// Resource groups
//
// Will always use the targetscope subscription.
//
// ----------------------------------------------------------------------------

@description('The Azure location. Needs to be specified since it can be different between resource groups.')
param location string

param environment string

param prefix string

@description('The name of the component. Use kebab-casing.')
param name string

param alertEmail string

// Will always be subscription since the value must be a compile-time constant
targetScope = 'subscription'

// Setup

resource currentResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
}

// ----------------------------------------------------------------------------
// APPLICATION INSIGHTS for telemetry
// ----------------------------------------------------------------------------

module applicationInsights '../application-insights/ai-for-environment.bicep' = {
  scope: resourceGroup(currentResourceGroup.name)
  name: '${deployment().name}-application-insights'
  params: {
    environment: environment
    location: location
    prefix: prefix
  }
}

// ----------------------------------------------------------------------------
// APPLICATION INSIGHTS for logging
// ----------------------------------------------------------------------------
module aiMonitor '../application-insights/ai-logging-monitor.bicep' = {
  scope: resourceGroup(currentResourceGroup.name)
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
module queryPack '../application-insights/query-pack.bicep' = {
  scope: resourceGroup(currentResourceGroup.name)
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

output resourceGroupId string = currentResourceGroup.id
output resourceGroupName string = currentResourceGroup.name
output applicationInsightsResourceId string = applicationInsights.outputs.applicationInsightsResourceId
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.applicationInsightsInstrumentationKey
output alertActionGroupId string = aiMonitor.outputs.alertActionGroupId

