// ----------------------------------------------------------------------------
// Resource groups
//
// Will always use the targetscope subscription.
//
// ----------------------------------------------------------------------------

@description('The Azure location. Needs to be specified since it can be different between resource groups.')
param location string

@description('The name of the component. Use kebab-casing.')
param name string

// Will always be subscription since the value must be a compile-time constant
targetScope = 'subscription'

// Setup

resource newResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
}

output resourceGroupId string = newResourceGroup.id
output resourceGroupName string = newResourceGroup.name
