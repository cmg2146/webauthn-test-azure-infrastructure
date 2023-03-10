# Webauthn-Test Infrastructure 
This repository contains Azure bicep files for deploying infrastructure for the webauthn-test project.

When adding a new resource type to a bicep file, make sure the corresponding resource provider is registerd in Azure.
Click [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider?tabs=azure-portal) to learn how to register a resource provider.

As a security precaution, the service connection/service principal used by the Azure DevOps pipeline to deploy the infrastructure does not have
permission to create role assignments. This is the default behavior when creating a service connection to Azure. Role assignments need to be created for the apps to pull images from the container registry because admin access is disabled for the registry. To create the necessary role assignments, an Azure admin needs to run the "acr-role-assignments.bicep" file manually, only one time, after the first run of the pipeline in the scope of the resource group containing the container registry. Read [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli) and [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-vscode) to deploy Bicep files manually.

## Configuration
The following environment variables are required by the pipeline. They have been configured in a variable group named
"webauthn-test-azure-infrastructure_Production" in Azure DevOps.

General Variables:
* AZURE_SERVICE_CONNECTION
  * The name of the service connection to Azure. A service connection must be created in Azure DevOps
  for the pipeline to communicate with Azure.
* RESOURCE_GROUP_NAME
  * The name of the resource group to create (or apply updates to if already created).
* RESOURCE_GROUP_LOCATION
  * The Azure region to create the resource group in (ignored after resource group is created).

Azure SQL Database:
* SQL_SERVER_NAME
  * The name of the SQL server instance.
* SQL_DATABASE_NAME
  * The name of the SQL server database. Will be created within the SQL server instance above.

Azure Key Vault:
* KEY_VAULT_NAME
  * The name of the key vault to create.
* API_DATAPROTECTION_KEY_NAME
  * The name of the key vault key used by the ASP.NET Core Data Protection library in the API App Service.

Azure App Services:
* APP_SERVICE_PLAN_NAME
  * The name of the app service plan.
* APP_SERVICE_PLAN_TIER
  * The tier of the app service plan.
* APP_SERVICE_PLAN_SKU
  * The SKU name of the app service plan.
* WEB_APP_SERVICE_NAME
  * The name of the Web/Frontend App Service.
* API_APP_SERVICE_NAME
  * The name of the API App Service.

Note: All resources will be created in the same Azure region the resource group is in.

## Notes
* TODO: Change database server admin to another AD user. Set API app service identity permissions to minimum required on database only.
* TODO: Remove app settings from bicep
* TODO: Setup a VNet