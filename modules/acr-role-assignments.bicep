targetScope = 'resourceGroup'

param containerRegistryName string = 'cmgdev'

param webAppServiceName string

@description('Principal Id of the Managed Service Identity for the Web App Service')
param webAppServicePrincipalId string

param apiAppServiceName string

@description('Principal Id of the Managed Service Identity for the API App Service')
param apiAppServicePrincipalId string

// Give the app service apps access to pull images from the ACR
var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource webAcrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(webAppServiceName)
  scope: containerRegistry
  properties: {
    principalId: webAppServicePrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRole
  }
}

resource apiAcrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(apiAppServiceName)
  scope: containerRegistry
  properties: {
    principalId: apiAppServicePrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRole
  }
}
