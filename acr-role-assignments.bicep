targetScope = 'resourceGroup'

@description('The name of the Container Registry to pull images from')
param containerRegistryName string = 'cmgdev'

@description('Specifies the name of the UI/frontend app service.')
param webAppServiceName string = 'webauthn-test'

@description('Specifies the name of the API app service.')
param apiAppServiceName string = 'webauthn-test-api'

@description('Specifies the name of the resource group containing the Web and API app services.')
param appServicesResourceGroup string = 'webauthn-test'

// Give the app service apps access to pull images from the ACR
var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource webAppService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: webAppServiceName
  scope: resourceGroup(appServicesResourceGroup)
}

resource apiAppService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: apiAppServiceName
  scope: resourceGroup(appServicesResourceGroup)
}

resource webAcrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(webAppServiceName)
  scope: containerRegistry
  properties: {
    principalId: webAppService.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRole
  }
}

resource apiAcrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(apiAppServiceName)
  scope: containerRegistry
  properties: {
    principalId: apiAppService.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRole
  }
}
