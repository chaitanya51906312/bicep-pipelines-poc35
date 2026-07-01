// Main Bicep template — composes reusable modules for the POC.
// Deployment scope: resource group.
targetScope = 'resourceGroup'

@description('Short prefix used to name resources.')
param prefix string = 'bicepoc'

@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Environment tag (dev/test/prod).')
param environment string = 'dev'

// Storage account names must be globally unique, lowercase, <=24 chars, no dashes.
var storageName = toLower('${prefix}${uniqueString(resourceGroup().id)}')
// Web app names must be globally unique.
var webAppName = '${prefix}-web-${uniqueString(resourceGroup().id)}'

var commonTags = {
  environment: environment
  managedBy: 'bicep'
  project: 'iac-poc'
}

module storage 'modules/storage.bicep' = {
  name: 'storageDeploy'
  params: {
    name: storageName
    location: location
    sku: 'Standard_LRS'
    tags: commonTags
  }
}

module appService 'modules/appservice.bicep' = {
  name: 'appServiceDeploy'
  params: {
    name: webAppName
    location: location
    planSku: 'B1'
    linuxFxVersion: 'NODE|18-lts'
    tags: commonTags
  }
}

output storageAccountName string = storage.outputs.storageAccountName
output webAppName string = appService.outputs.webAppName
output webAppUrl string = 'https://${appService.outputs.webAppDefaultHostName}'
