@description('Name of the App Service (web app), globally unique.')
param name string

@description('Azure region.')
param location string

@description('App Service Plan SKU.')
@allowed([
  'B1'
  'S1'
  'P1v3'
])
param planSku string = 'B1'

@description('Linux runtime stack for the web app.')
param linuxFxVersion string = 'NODE|18-lts'

@description('Tags applied to the resources.')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${name}-plan'
  location: location
  sku: {
    name: planSku
  }
  kind: 'linux'
  properties: {
    reserved: true // required for Linux plans
  }
  tags: tags
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }
  tags: tags
}

output webAppName string = webApp.name
output webAppDefaultHostName string = webApp.properties.defaultHostName
