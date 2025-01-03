# azure-network-security-perimeter

## What does this script do? 
This script deploys a KeyVault, two Storage Accounts, a Network Security perimeter and a log analytics workspace. The intent of this script is to deploy a demo environment for [Network Security Perimeter](https://learn.microsoft.com/en-us/azure/private-link/network-security-perimeter-concepts). 

## Variables 
Set the following variables before you run the script: 
| Variable | Description |
| -------- | ----------- | 
| Location | Region name. Please make sure you select a supported region during the [public preview] (https://learn.microsoft.com/en-us/azure/private-link/network-security-perimeter-concepts#regional-limitations) |
| rgName   | Resource Group Name | 
| objID    | Object ID of the user that you use to login to Azure. Go to Entra ID --> Users --> Select the users --> Object ID. | 
| SubID    | Subscription ID where you deploy the demo | 

## How to run the script? 
During the public preview, logging cannot be enabled programmatically using PowerShell. There is a break on line 38. Please run the script from line 1-37 first, enable logging on the NSP and run line 39 till the end afterwards. 

## Demo 
The script deploys two storage accounts, one of the storage account has Customer Managed Keys (CMK) enabled with the keys stored in KeyVault. 

Demo1: Using the NSP, the storage account connects to AKV without enabling trusted services on AKV. With the NSP in enforced mode, you cannot communicate to AKV or the storage account without explicitly giving IP or subscription access to the NSP. However, the services within the NSP are trusted and can communicate with each other. 

Demo2: Switch the resources in the NSP from enforced back to learning mode. Observe how to logfiles within the NSP capture the requests to the keyvault and the storage account, but are not enforced.  

Demo3: Enable a private endpoint on the storage account. Private endpoints are not part of the NSP and not impacted by the enforcement of the NSP.



