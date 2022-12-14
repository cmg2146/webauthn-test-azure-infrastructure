# Webauthn-Test Infrastructure 
This repository contains Azure bicep files for deploying infrastructure for the webauthn-test project.

When adding a new resource type to a bicep file, make sure the corresponding resource provider is registerd in Azure.
Click [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider?tabs=azure-portal) to learn how to register a resource provider.

As a security precaution, the service connection/service principal used by the Azure DevOps pipeline to deploy the infrastructure does not have
permission to create role assignments. This is the default behavior when creating a service connection to Azure. Role assignments need to be created for the apps to pull images from the container registry because admin access is disabled for the registry. To create the necessary role assignments, an Azure admin needs to run the "acr-role-assignments.bicep" file manually, only one time, after the first run of the pipeline in the scope of the resource group containing the container registry. Read [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli) and [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-vscode) to deploy Bicep files manually.

* TODO: Change database server admin to another AD user and set API app service identity permissions to minimum required on database only
* TODO: Upgrade app service to basic tier
* TODO: Remove app settings from bicep
* TODO: Setup a VNet