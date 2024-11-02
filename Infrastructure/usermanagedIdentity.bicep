resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'userAssignedIdentty-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
}

output principalId string = managedIdentity.properties.principalId
output userAssignedIdentityId string = managedIdentity.id
