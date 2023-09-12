// ----------------------------------------------------------------------------
// APPLICATION INSIGHTS logging monitor
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The customer environment, like "test" or "prod"')
param environment string

@description('If set, used to prefix resource names')
param prefix string = ''

@description('Action group email to send alerts to')
param alertEmail string

@description('Action group short name')
param actionGroupName string = 'Alerts'

@description('Name of the email receiver entry')
param emailReceiverName string = 'Teams channel'

// Setup
var dashedPrefix = endsWith(prefix, '-') ? prefix : '${prefix}-'

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${dashedPrefix}${environment}-monitor-log-workspace'
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource aiMonitor 'Microsoft.Insights/components@2020-02-02' = {
  name: '${dashedPrefix}${environment}-monitor'
  location: location
  kind: 'other'
  properties: {
    Application_Type: 'other'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    IngestionMode: 'LogAnalytics'
    WorkspaceResourceId: workspace.id
  }
}

resource alertActionGroup 'microsoft.insights/actionGroups@2023-01-01' = {
  name: 'action-group-${environment}'
  location: location
  properties: {
    groupShortName: actionGroupName
    enabled: true
    emailReceivers: [
      {
        name: emailReceiverName
        emailAddress: alertEmail
        useCommonAlertSchema: false
      }
    ]
  }
}

// ----------------------------------------------------------------------------
// OUTPUT
// ----------------------------------------------------------------------------

output aiMonitorResourceId string = aiMonitor.id
output aiMonitorInstrumentationKey string = aiMonitor.properties.InstrumentationKey
output alertActionGroupId string = alertActionGroup.id
