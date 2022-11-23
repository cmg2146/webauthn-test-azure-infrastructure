targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the SQL logical server.')
param sqlServerName string = 'webauthn-test-sql'

@description('The name of the SQL Database.')
param sqlDatabaseName string = 'WebAuthnTest'

@description('Specifies the name of the key vault.')
param keyVaultName string = 'webauthn-test-vault'

@description('Specifies the name of the app service plan.')
param appServicePlanName string = 'webauthn-test-app-plan'

@description('Specifies the name of the UI/frontend app service.')
param webAppServiceName string = 'webauthn-test'

@description('Specifies the name of the API app service.')
param apiAppServiceName string = 'webauthn-test-api'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    tier: 'Free'
    name: 'F1'
  }
  properties: {
    reserved: true
    zoneRedundant: false
  }
}

resource webAppService 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppServiceName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      //default docker image is overwritten on first code deployment
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
      ftpsState: 'FtpsOnly'
      acrUseManagedIdentityCreds: true
      http20Enabled: true
      minTlsVersion: '1.2'
    }
  }
}

resource apiAppService 'Microsoft.Web/sites@2022-03-01' = {
  name: apiAppServiceName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      //default docker image is overwritten on first code deployment
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
      ftpsState: 'FtpsOnly'
      acrUseManagedIdentityCreds: true
      http20Enabled: true
      minTlsVersion: '1.2'
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    publicNetworkAccess: 'disabled'
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: apiAppService.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'all'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: sqlServerName
  location: location
  properties: {
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    administrators: {
      //TODO: Not a good practice to make the app service identity a server admin, change this
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      principalType: 'Application'
      login: apiAppService.name
      tenantId: apiAppService.identity.tenantId
      sid: apiAppService.identity.principalId
    }
    minimalTlsVersion: '1.2'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    capacity: 10
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 10737418240
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
    highAvailabilityReplicaCount: 0
    isLedgerOn: false
    readScale: 'Disabled'
  }
}

resource sqlFirewallRules 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

//configure app settings and connection strings.
resource webAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: webAppService
  properties: {
    API_URL: 'https://${apiAppService.properties.defaultHostName}'
  }
}

resource apiAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: apiAppService
  properties: {
    ASPNETCORE_ENVIRONMENT: 'Production'
    WEB_URL: 'https://${webAppService.properties.defaultHostName}'
    AZURE_KEY_VAULT_ID: keyVault.id
  }
}

resource apiConnectionStrings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'connectionstrings'
  kind: 'string'
  parent: apiAppService
  properties: {
    Default: {
      type: 'SQLAzure'
      value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};MultipleActiveResultSets=True;Authentication=Active Directory Managed Identity;TrustServerCertificate=False;Encrypt=True'
    }
  }
}
