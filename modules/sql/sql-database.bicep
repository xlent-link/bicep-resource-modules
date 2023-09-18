// ----------------------------------------------------------------------------
// SQL DATABASE
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('If using a database, the sql server to maybe create a database in')
param sqlServerName string = ''

@description('If using a database, this is the name of the database')
param databaseName string = ''

param databaseSkuName string = 'Basic'
param databaseSkuTier string = 'Basic'


resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview' existing = {
  name: sqlServerName
}

resource sql 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
}
