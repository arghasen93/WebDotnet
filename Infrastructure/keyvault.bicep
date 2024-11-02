param objectId string
param userAssignedIdentity string
@secure()
@minLength(8)
param vmadminpassword string
param pfxbase64 string
@secure()
param pfxpassword string

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'keyvault-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: objectId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'list'
            'get'
          ]
        }
      }
      {
        tenantId: tenant().tenantId
        objectId: userAssignedIdentity
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'list'
            'get'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource vmadminpasswordsecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'vmadminpassword'
  properties: {
    value: vmadminpassword
  }
}


resource pfxpasswordsecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'pfxpassword'
  properties: {
    value: pfxpassword
  }
}

resource pfxbase64Secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'pfxbase64'
  properties: {
    value: pfxbase64
  }
}

output kevaultname string = keyVault.name

