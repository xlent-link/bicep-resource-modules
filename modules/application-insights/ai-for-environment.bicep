// ----------------------------------------------------------------------------
// APPLICATION INSIGHTS
//
// For the environment
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The customer environment, like "test" or "prod"')
param environment string

@description('If set, used to prefix resource names')
param prefix string = ''

@description('The daily quota')
param dailyQuotaGB int = 5

// Setup
var dashedPrefix = endsWith(prefix, '-') ? prefix : '${prefix}-'

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${dashedPrefix}${environment}-log-workspace'
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGB
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${dashedPrefix}${environment}-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    IngestionMode: 'LogAnalytics'
    WorkspaceResourceId: workspace.id
  }
}

resource pricingPlan 'microsoft.insights/components/pricingPlans@2017-10-01' = {
  name: 'current'
  parent: applicationInsights
  properties: {
    cap: dailyQuotaGB
    warningThreshold: 90
    planType: 'Basic'
  }
}

// ----------------------------------------------------------------------------
// OUTPUT
// ----------------------------------------------------------------------------

output applicationInsightsResourceId string = applicationInsights.id
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
