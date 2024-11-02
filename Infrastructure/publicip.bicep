param count int
resource publicIps 'Microsoft.Network/publicIPAddresses@2022-05-01' =  [for i in range(0, count): {
  name: 'publicIp-${uniqueString(resourceGroup().id)}-${i}'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]



output publicipIds array =  [for i in range(0,2) : resourceId('Microsoft.Network/publicIPAddresses','publicIp-${uniqueString(resourceGroup().id)}-${i}')]
