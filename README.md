# Infrastructure 
This repository contains Azure bicep files for deploying infrastructure for the webauthn-test project.

When adding a new resource type to a bicep file, you need to make sure the corresponding resource provider
is registerd in Azure. Click [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider?tabs=azure-portal) to learn how to register a resource provider.