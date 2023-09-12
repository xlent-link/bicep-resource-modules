// ----------------------------------------------------------------------------
// HEALTH CHECKING
// ----------------------------------------------------------------------------

@description('Name of the health check Web test')
param name string

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('Which application insights instance to use for health checking')
param applicationInsightsResourceId string

@description('The url to ping')
param url string

@description('If set, this is the action group that is used for alerts')
param alertActionGroupId string = ''

// https://learn.microsoft.com/en-us/rest/api/application-insights/web-tests/get?tabs=HTTP

resource webTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: name
  location: location
  tags: {
    'hidden-link:${applicationInsightsResourceId}' : 'Resource'
    //'hidden-link:/subscriptions/${subscriptionId}/resourceGroups/${rg}/providers/microsoft.insights/components/${appInsightsName}': 'Resource'
  }
  kind: 'standard'
  properties: {
    Name: name
    Enabled: true
    Frequency: 300 // TODO: can we reduce to 120 or 60? Should we?
    Timeout: 30
    Kind: 'standard'

    // https://learn.microsoft.com/en-us/previous-versions/azure/azure-monitor/app/monitor-web-app-availability#location-population-tags
    Locations: [
      { Id: 'emea-gb-db3-azr' }  // North Europe
      { Id: 'emea-se-sto-edge' } // UK West
      { Id: 'emea-ru-msa-edge' } // UK South
      { Id: 'emea-nl-ams-azr' }  // West Europe
      { Id: 'emea-ch-zrh-edge' } // France South
    ]
    Request: {
      FollowRedirects: true
      HttpVerb: 'GET'
      ParseDependentRequests: false
      RequestUrl: url
    }
    RetryEnabled: true
    SyntheticMonitorId: name
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      SSLCertRemainingLifetimeCheck: 7
      SSLCheck: true
    }
  }
}

resource healthCheckAlert 'microsoft.insights/metricalerts@2018-03-01' = {
  name: '${name}-alert-rule'
  location: 'global'
  tags: {
    'hidden-link:${applicationInsightsResourceId}': 'Resource'
    'hidden-link:${webTest.id}': 'Resource'
  }
  properties: {
    description: 'Monitors the /health endpoint of the components in the platform'
    severity: 1
    enabled: true
    scopes: [
      applicationInsightsResourceId
      webTest.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: webTest.id
      componentId: applicationInsightsResourceId
      failedLocationCount: 2
    }
    actions: [
      {
        actionGroupId: alertActionGroupId
      }
    ]
  }
}
