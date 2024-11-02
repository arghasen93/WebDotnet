param subnetName string
param vnetName string
param publicIpId string
param webappName string
@secure()
param pfxbase64 string
param userAssignedIdentityId string
@secure()
param pfxpassword string
param hostName string

var appgatewayName = 'appgateway-${uniqueString(resourceGroup().id)}'
var appgatewayFrontendpublicIpConfig = 'applicationGateway-publicip-frontendconfig-${uniqueString(resourceGroup().id)}'
var appgatewayFrontendprivateIpConfig = 'applicationGateway-privateip-frontendconfig-${uniqueString(resourceGroup().id)}'
var appgatewayFrontendHttpsport = 'applicationGateway-frontendport-443-${uniqueString(resourceGroup().id)}'
var appgatewayFrontendHttpport = 'applicationGateway-frontendport-80-${uniqueString(resourceGroup().id)}'
var appgatewayHttpsListner = 'applicationGateway-HTTPS-${uniqueString(resourceGroup().id)}'
var appgatewayHttpListner = 'applicationGateway-HTTP-${uniqueString(resourceGroup().id)}'
var appgatewayBackendpool = 'applicationGateway-backendpool-${uniqueString(resourceGroup().id)}'
var appgatewayBackendSetting = 'applicationGateway-backendsettings-${uniqueString(resourceGroup().id)}'
var appgatewayRoutingRule = 'applicationGateway-routing-${uniqueString(resourceGroup().id)}'
var appgatewayRedirectConfig = 'applicationGateway-redirect-config-${uniqueString(resourceGroup().id)}'
var appgatewayRedirectRoutingRule = 'applicationGateway-redirect-routing-${uniqueString(resourceGroup().id)}'
var gatewayIPConfigurations = 'applicationGateway-gatewayIPConfigurations-${uniqueString(resourceGroup().id)}'
var healthProbe = 'healthprobe-${uniqueString(resourceGroup().id)}'
var rewriteruleset = 'rewriteruleset-${uniqueString(resourceGroup().id)}'

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: appgatewayName
  location: resourceGroup().location
  identity: {
    type:'UserAssigned'
    userAssignedIdentities:{
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: gatewayIPConfigurations
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appgatewayFrontendpublicIpConfig
        properties: {
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
      {
        name: appgatewayFrontendprivateIpConfig
        properties: {
          subnet:{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.10'
        }
      }
    ]
    frontendPorts: [
      {
        name: appgatewayFrontendHttpsport
        properties: {
          port: 443
        }
      }
      {
        name: appgatewayFrontendHttpport
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: appgatewayBackendpool
        properties:{
          backendAddresses:[
            {
              fqdn: '${webappName}.azurewebsites.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appgatewayBackendSetting
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          probe:{
            id: resourceId('Microsoft.Network/applicationGateways/probes', appgatewayName, healthProbe)
          }
        }
      }
    ]
  
    httpListeners: [
      {
        name: appgatewayHttpsListner
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgatewayName, appgatewayFrontendprivateIpConfig)
          }
          frontendPort: {
            id:  resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgatewayName, appgatewayFrontendHttpsport)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appgatewayName, 'sslcertificate')
          }
          hostName: hostName
        }
      }
      {
        name: appgatewayHttpListner
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgatewayName, appgatewayFrontendprivateIpConfig)
          }
          frontendPort: {
            id:  resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgatewayName, appgatewayFrontendHttpport)
          }
          protocol: 'Http'
          hostName: hostName
        }
      }
    ]
    sslCertificates: [
      {
        name:'sslcertificate'
        properties:{
          password: pfxpassword
          data: pfxbase64
        }
      }
    ]
    redirectConfigurations:[
      {
        name: appgatewayRedirectConfig
        properties: {
         includePath: true
          includeQueryString: true
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgatewayName, appgatewayHttpsListner)
          }
        }
      }
    ]

    requestRoutingRules: [
      {
        name: appgatewayRoutingRule
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgatewayName, appgatewayHttpsListner)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appgatewayName, appgatewayBackendpool)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appgatewayName, appgatewayBackendSetting)
          }
          rewriteRuleSet: {
            id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', appgatewayName, rewriteruleset)
          }
          priority:1
        }
      }
      {
        name: appgatewayRedirectRoutingRule
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgatewayName, appgatewayHttpListner)
          }
          redirectConfiguration:{
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', appgatewayName, appgatewayRedirectConfig)
          }
          priority:2
        }
      }
    ]

    probes:[
      {
        name: healthProbe
        properties:{
          unhealthyThreshold: 5
          pickHostNameFromBackendHttpSettings:true
          interval: 60
          path: '/'          
          protocol:'Https'
          port:443  
          timeout: 30      
        }
      }
    ]
    rewriteRuleSets:[
      {
        name: rewriteruleset
        properties:{
          rewriteRules:[
            {
              name:'AAD Login Redirect'
              ruleSequence: 100
              conditions:[
                {
                  variable: 'http_resp_Location'
                  ignoreCase: true
                  pattern: '(.*)(redirect_uri=https%3A%2F%2F)${webappName}\\.azurewebsites\\.net(.*)$'
                  negate: false
                }
              ]
              actionSet:{
                responseHeaderConfigurations: [
                  {
                    headerName:'Location'
                    headerValue: '{http_resp_Location_1}{http_resp_Location_2}{var_host}{http_resp_Location_3}'
                  }
                ]
              }
            }
            {
              name:'AAD Callback'
              ruleSequence: 101
              conditions:[
                {
                  variable: 'http_resp_Location'
                  ignoreCase: true
                  pattern: '(https:\\/\\/)${webappName}\\.azurewebsites\\.net(.*)$'
                  negate: false
                }
              ]
              actionSet:{
                responseHeaderConfigurations: [
                  {
                    headerName:'Location'
                    headerValue: 'https://{var_host}{http_resp_Location_2}'
                  }
                ]
              }
            }
          ]
        }
      }
    ]
  }
}

output appgatewayPrivateIp string = applicationGateway.properties.frontendIPConfigurations[1].properties.privateIPAddress
