param adminUsername string
@secure()
param adminPassword string
param publicIpId string
param vnetName string
param subnetName string

resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'vmhost'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: 'disk-${uniqueString(resourceGroup().id)}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  dependsOn:[
    networkSecurityGroup
  ]
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: 'nsg-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}


resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nic-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress:'10.0.1.6'
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: publicIpId
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
  }
}

// resource windowsVMExtensions 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
//   parent: windowsVM
//   name: 'vm-extension-${uniqueString(resourceGroup().id)}'
//   location: resourceGroup().location
//   properties: {
//     publisher: 'Microsoft.Compute'
//     type: 'CustomScriptExtension'
//     typeHandlerVersion: '1.10'
//     autoUpgradeMinorVersion: true
//     protectedSettings: {
//       commandToExecute: 'powershell -Command "Install-WindowsFeature -Name DNS -IncludeManagementTools -Confirm:$false; Start-Service -Name DNS; Add-DnsServerResourceRecordA -Name \'www\' -ZoneName \'free-webspace.site\' -IPv4Address \'10.0.0.10\'; Write-Output \'DNS Server setup complete with zones and A records created.\'"'
//     }
//   }
// }
