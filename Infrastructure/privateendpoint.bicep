param privateLinkServiceId string
param subnetId string
param webappName string
param virtualNetworkId string
param virtualNetworkName string

var customDnsConfigs = [
  {
    fqdn: '${webappName}.azurewebsites.net'
  }
  {
    fqdn: '${webappName}.scm.azurewebsites.net'
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: virtualNetworkName
}


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'privateendpoint-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'privatelink-${uniqueString(resourceGroup().id)}'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            'sites'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: subnetId
    }
    customDnsConfigs: customDnsConfigs
  }
  dependsOn: [
    virtualNetwork
  ]
}


resource privateDnsZones 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones
  name: '${privateDnsZones.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZones.id
        }
      }
    ]
  }
}
