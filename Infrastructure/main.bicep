param vnetaddressprefix array = ['10.0.0.0/16']
param subnets array =  [
    {
      name: 'gateway-subnet'
      properties: {
        addressPrefix: '10.0.0.0/24'
      }
    }
    {
      name: 'private-endpoint-subnet'
      properties: {
        addressPrefix: '10.0.1.0/24'
      }
    }
  ]


param objectId string
@secure()
param vmadminpassword string
param vmadminusername string
param pfxbase64 string
@secure()
param pfxpassword string
param zoneName string
param publicIpCount int

var hostName = format('www.{0}', zoneName)

module vnet 'vnet.bicep' = {
  name: 'vnet-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params: {
   addressPrefixes: vnetaddressprefix
   subnets: subnets 
  }
}

module applicationInsights 'applicaioninsight.bicep' = {
  name: 'applicationInsight-${deployment().name}-${uniqueString(resourceGroup().id)}'
}

module appservice 'appservice.bicep' = {
  name: 'appservice-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params:{
    applicationInsightConnection: applicationInsights.outputs.appInsightConnectionString
  }
}

module privateendpoint 'privateendpoint.bicep' = {
  name: 'privateendpoint-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params: {
    privateLinkServiceId: appservice.outputs.webappId
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets',vnet.outputs.vnetName ,subnets[1].name)
    webappName: appservice.outputs.webappName
    virtualNetworkId: vnet.outputs.vnetId
    virtualNetworkName: vnet.outputs.vnetName
  }
}


module keyvault 'keyvault.bicep' = {
  name: 'keyvault-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params:{
    pfxpassword: pfxpassword
    pfxbase64: pfxbase64
    objectId: objectId
    vmadminpassword: vmadminpassword
    userAssignedIdentity: userAssignedIdentity.outputs.principalId
  }
  dependsOn:[
    userAssignedIdentity
  ]
}

resource keyVaultref 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyvault.outputs.kevaultname
}

module publicIpAddress 'publicip.bicep' = {
  name: 'publicIpAddress-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params: {
    count: publicIpCount
  }
}

module virtualmachine 'vm.bicep' = {
  name: 'virtualmachine-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params: {
    adminPassword: keyVaultref.getSecret('vmadminpassword')
    adminUsername: vmadminusername
    publicIpId: publicIpAddress.outputs.publicipIds[0]
    subnetName: subnets[1].name
    vnetName: vnet.outputs.vnetName
  }
}
module userAssignedIdentity 'usermanagedIdentity.bicep' = {
  name: 'userAssignedIdentity-${deployment().name}-${uniqueString(resourceGroup().id)}'
}
module applicationgateway 'applicationgateway.bicep' = {
  name: 'applicationgateway-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params: {
    publicIpId: publicIpAddress.outputs.publicipIds[1]
    subnetName: subnets[0].name
    vnetName: vnet.outputs.vnetName
    webappName: appservice.outputs.webappName
    userAssignedIdentityId: userAssignedIdentity.outputs.userAssignedIdentityId
    pfxbase64: keyVaultref.getSecret('pfxbase64')
    pfxpassword: keyVaultref.getSecret('pfxpassword')
    hostName: hostName
  }

  dependsOn:[
    vnet
    appservice
    keyvault
    userAssignedIdentity
  ]
}

module customPrivateDNSzone 'customprivateDNSzone.bicep' = {
  name: 'customPrivateDNSzone-${deployment().name}-${uniqueString(resourceGroup().id)}'
  params: {
    virtualNetworkId: vnet.outputs.vnetId
    zoneName: zoneName
  }
}
