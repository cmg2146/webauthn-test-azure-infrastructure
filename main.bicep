targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the SQL logical server.')
param sqlServerName string

@description('The name of the SQL Database.')
param sqlDatabaseName string

@description('Specifies the name of the key vault.')
param keyVaultName string

@description('Specifies the name of the key vault.')
param apiDataProtectionKeyName string

@description('Specifies the name of the app service plan.')
param appServicePlanName string

@description('Specifies the name of the app service plan tier.')
param appServicePlanTier string

@description('Specifies the name of the app service plan SKU.')
param appServicePlanSku string

@description('Specifies the name of the UI/frontend app service.')
param webAppServiceName string

@description('Specifies the name of the API app service.')
param apiAppServiceName string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    tier: appServicePlanTier
    name: appServicePlanSku
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
    publicNetworkAccess: 'Enabled'
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
            'get'
            'wrapKey'
            'unwrapKey'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource apiDataprotectionKey 'Microsoft.KeyVault/vaults/keys@2021-11-01-preview' = {
  name: apiDataProtectionKeyName
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
      exportable: false
    }
    curveName: 'P-521'
    keyOps: [
      'wrapKey'
      'unwrapKey'
    ]
    keySize: 2048
    kty: 'RSA'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P30D'
      }
      lifetimeActions: [
        { 
          action: {
            type: 'rotate'
          }
          trigger: {
            timeBeforeExpiry: 'P7D'
          }
        }
      ]
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
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      // TODO: It is a bad practice to make the app identity a server admin, like below. For a real app,
      // this should never be done - a separate AD account should be the server admin and the app identity
      // should be given access only to necessary databases and with only necessary permissions.     
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
