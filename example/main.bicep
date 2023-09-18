// ----------------------------------------------------------------------------
// MAIN
//
// Entry point for deployment
// ----------------------------------------------------------------------------

@description('The environment to create/update. Production environment will have higher SKUs.')
@allowed([
  'test' // Test environment
  'prod' // Production environment
])
param environment string = 'test'

@description('SQL server access by Group in Azure AD. The name of the group (with no spaces).')
param dbAdminGroupName string = 'IntegrationPlatformCoreTeam'
@description('SQL server access by Group in Azure AD. The object id of the group.')
param dbAdminGroupObjectId string = '6468c8dd-12a1-42e7-aff4-xxxxx'

@description('Key vault access by Group in Azure AD. The object id of the group.')
param keyVaultGroupObjectId string = '6468c8dd-12a1-42e7-aff4-xxxxx'

@description('Email address to teams channel that receives alerts')
param alertEmail string = 'info@example.com'

@description('Azure location for all resources. Defaults to same location as resource group.')
param location string = resourceGroup().location

var prefix = 'logent-ip'

// ----------------------------------------------------------------------------
// COMMON RESOURCES
// ----------------------------------------------------------------------------
@description('Create common basics like Application Insights and SQL server')
module common 'common.bicep' = {
  name: '${deployment().name}-common'
  params: {
    location: location
    environment: environment
    adminGroupObjectName: dbAdminGroupName
    adminGroupObjectId: dbAdminGroupObjectId
    alertEmail: alertEmail
    prefix: prefix
  }
}

// ----------------------------------------------------------------------------
// ARTCIC TERN RESOURCES
// ----------------------------------------------------------------------------
@description('Create resources for Arctic Tern component')
module arcticTern '../modules/sites/function-app.bicep' = {
  name: '${deployment().name}-arctictern'
  params: {
    location: location
    environment: environment
    name: 'arctictern'
    storageAccountName: 'atern${environment}${uniqueString(resourceGroup().id)}'
    prefix: prefix
    useKeyVault: true
    sqlServerName: common.outputs.sqlServerName
    sqlDatabaseName: 'tracking-${environment}'
    apimBackends: [ 
      {
        apiName: 'transport-management-api'
        path: '/transport-management/v1'
      }
    ]
    apimName: common.outputs.apimName
    apimHostKey: common.outputs.functionAppHostKey
    healthCheckApplicationInsightsResourceId: common.outputs.applicationInsightsResourceId
    applicationInsightsInstrumentationKey: common.outputs.applicationInsightsInstrumentationKey
    alertActionGroupId: common.outputs.alertActionGroupId
    keyVaultGroupObjectId: keyVaultGroupObjectId
  }
}

// ----------------------------------------------------------------------------
// LAPWING RESOURCES
// ----------------------------------------------------------------------------
@description('Create resources for Lapwing component')
module lapwing '../modules/sites/function-app.bicep' = {
  name: '${deployment().name}-lapwing'
  params: {
    location: location
    environment: environment
    name: 'lapwing'
    storageAccountName: 'lwing${environment}${uniqueString(resourceGroup().id)}'
    prefix: prefix
    useKeyVault: true
    healthCheckApplicationInsightsResourceId: common.outputs.applicationInsightsResourceId
    applicationInsightsInstrumentationKey: common.outputs.applicationInsightsInstrumentationKey
    alertActionGroupId: common.outputs.alertActionGroupId
    keyVaultGroupObjectId: keyVaultGroupObjectId
  }
}
