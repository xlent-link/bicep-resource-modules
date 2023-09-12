// ----------------------------------------------------------------------------
// Merge app settings.
// If set by siteConfig on function-app, that will erase any other app setting.
// ----------------------------------------------------------------------------

@description('The name of the site, e.g. a function app')
param siteName string

@description('App settings dictionary')
param appSettings object

@description('Current app settings of the site')
param currentAppSettings object

resource siteconfig 'Microsoft.Web/sites/config@2022-03-01' = {
  name: '${siteName}/appsettings'
  properties: union(currentAppSettings, appSettings)
}
