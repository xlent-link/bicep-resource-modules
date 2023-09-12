// ----------------------------------------------------------------------------
// QUERY PACK
//
// Creates reusable Kusto queries
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The customer environment, like "test" or "prod"')
param environment string

@description('An array of obects containing "id", "name" and "query"')
param queries array

// ----------------------------------------------------------------------------
// Pack of queries
// ----------------------------------------------------------------------------
resource queryPacks 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
  name: 'monitor-query-packs-${environment}'
  location: location
  properties: {}
}

resource querypacks 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = [for entry in queries: {
  parent: queryPacks
  name: entry.id
  properties: {
    displayName: entry.name
    body: entry.query
    related: {
      resourceTypes: [
        'microsoft.insights/components'
      ]
    }
  }
}]
