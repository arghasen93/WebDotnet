param addressPrefixes array
param subnets array
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
  }
}

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
