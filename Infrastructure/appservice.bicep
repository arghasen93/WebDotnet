param applicationInsightConnection string

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: 'appserviceplan-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name: 'B1'
    capacity: 1
  }
  kind:'windows'
}


resource webApplication 'Microsoft.Web/sites@2023-12-01' = {
  name: 'webapplication-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig:{
      netFrameworkVersion: 'v4.0'
      metadata: [
        {
          name:'CURRENT_STACK'
          value: 'dotnet'
        }
      ]
      publicNetworkAccess: 'Enabled'
      ipSecurityRestrictions: [
        {
          ipAddress: 'Any'
          action: 'Deny'
          priority: 2147483647
          name: 'Deny all'
          description: 'Deny all access'
        }
      ]
      ipSecurityRestrictionsDefaultAction: 'Deny'
      scmIpSecurityRestrictions: [
        {
          ipAddress: 'Any'
          action: 'Allow'
          priority: 2147483647
          name: 'Allow all'
          description: 'Allow all access'
        }
      ]
      scmIpSecurityRestrictionsDefaultAction: 'Allow'
      scmIpSecurityRestrictionsUseMain: false
      appSettings: [
        {
          name:'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightConnection
        }
      ]
    }
    
  }
}

output webappId string = webApplication.id
output webappName string = webApplication.name
