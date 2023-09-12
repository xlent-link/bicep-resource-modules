// ----------------------------------------------------------------------------
// SQL SERVER
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The name of the sql server instance')
param name string

@description('RBAC access to this AD group')
param dbAdminGroupName string

@description('RBAC access to this AD group')
param dbAdminGroupObjectId string

@description('The sql servers needs an admin login')
param administratorLogin string = 'sysadmin'

@description('The sql servers needs an admin password. Only used at first creation.')
@secure()
param administratorLoginPassword string

resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    administrators: {
      azureADOnlyAuthentication: false // Note: The migrator sql user uses password access from Azure DevOps
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: dbAdminGroupName
      sid: dbAdminGroupObjectId
      tenantId: subscription().tenantId
    }
  }
}

resource AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2022-11-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
