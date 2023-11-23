# About script 

To use the script, the first step is to go to this repository and clone it [https://github.com/Cosmo-Tech/azure-platform-deployment-tools](https://github.com/Cosmo-Tech/azure-platform-deployment-tools/tree/MTOR/autodeployment_babylon/deploy_with_Babylon). The script is used for automating the installation of Babylon in deb mode and also automating the deployment of the solution in Azure.

## Prerequisites

* Create a folder of your choice.
* ---> Copy the script you have cloned into this folder.
* ---> Inside this folder, create a directory named `adx` and another named `dataset`
* ---> also, inside this folder, create a directory named `powerbi`," and within that, create folders named `dashboard` and `scenario`.
* ---> Additionally, it is required to prepare a file named `asset.dev.solution.yaml` beforehand.
Like this:
```bash
.
.
├── adx
│   └── Create.kql
├── asset.dev.solution.yaml
├── dataset
├── deploy_comsotechsolution_babylon.sh
└── powerbi
    ├── dashboard
    │   └── asset_dev_dashboard.pbix
    └── scenario
        └── Asset_Staging_Demo_Dashboard_Baseline.pbix

5 directories, 5 files
```
The `dataset` folder contains all the CSV files for your solution.

## run the scripte 

To run this script, use the following command:

```bash 
source ./deploy_comsotechsolution_babylon.sh asset dev
```

## Simple demo 
```bash 
source ./deploy_comsotechsolution_babylon.sh asset dev                   ──(Mon,Nov20)─┘
[ + OK ] Syntax correct.  Welcome to the deployment the solution asset with  Babylon

------------------------------------------Babylon Dev mode installation---------------------------------------
[+] Starting the installation of :  Babylon 
Cloning into 'Babylon'...
remote: Enumerating objects: 11647, done.
remote: Counting objects: 100% (3357/3357), done.
remote: Compressing objects: 100% (1165/1165), done.
remote: Total 11647 (delta 2234), reused 2674 (delta 1917), pack-reused 8290
Receiving objects: 100% (11647/11647), 4.74 MiB | 450.00 KiB/s, done.
Resolving deltas: 100% (6584/6584), done.
[5] 48730
Installing dependencies... |/-\[5]  + 48730 done       ( pip install -e . > /dev/null; )
Installing dependencies... Done
[+]  Successful installation of Babylon
Usage: babylon [OPTIONS] COMMAND [ARGS]...

   ____              __                 ___  
  /\  _`\           /\ \               /\_ \  
  \ \ \L\ \     __  \ \ \____   __  __ \//\ \      ___     ___  
   \ \  _ <'  /'__`\ \ \ '__`\ /\ \/\ \  \ \ \    / __`\ /' _ `\  
    \ \ \L\ \/\ \L\.\_\ \ \L\ \\ \ \_\ \  \_\ \_ /\ \L\ \/\ \/\ \  
     \ \____/\ \__/.\_\\ \_,__/ \/`____ \ /\____\\ \____/\ \_\ \_\  
      \/___/  \/__/\/_/ \/___/   `/___/> \\/____/ \/___/  \/_/\/_/  
                                    /\___/  
                                    \/__/  
                                                             v3.5.2

  CLI used for cloud interactions between CosmoTech and multiple cloud
  environment

  The following environment variables are required:

  - BABYLON_SERVICE: Vault Service URI
  - BABYLON_TOKEN: Access Token Vault Service
  - BABYLON_ORG_NAME: Organization Name
      

Options:
  -v, --verbosity LVL     Either CRITICAL, ERROR, WARNING, INFO or DEBUG
  --bare, --raw, --tests  Enable test mode, this mode changes output
                          formatting.
  -n, --dry-run           Will run commands in dry-run mode.
  --version               Print version number and return.
  --help                  Show this message and exit.

Commands:
  api              Cosmotech API
  azure            Group allowing communication with Microsoft Azure Cloud
  config           Group made to work on the config
  github           Group allowing communication with Github REST API
  hvac             Group handling Vault Hashicorp
  plugin           Subgroup for plugins
  powerbi          Group handling communication with PowerBI API
  state            Group made to work on the babylon state
  terraform-cloud  Group allowing interactions with the Terraform Cloud API
  webapp           Group handling Cosmo Sample WebApp configuration

------->  Setup environment variables
-----> We have 4 required environment variables for Babylon Works:
---> Enter the BABYLON_SERVICE Variable : 
 EX: https://engineering.uksouth.cloudapp.azure.com/
---> Enter the BABYLON_TOKEN Variable : 
 EX: Contact the Cloud team
---> Enter the BABYLON_ORG_NAME Variable : 
 EX: cosmotech
---> Enter the BABYLON_ENCODING_KEY Variable : 
Took a look at the document of Babylon
 EX: babylon azure token store -c brewery -p perf --scope powerbi
-----> We can set all the necessary environment variables for your solution asset:
---> Enter Your Email Variable : 
 EX: user@cosmotech.com
mohcine.tor@cosmotech.com
---> Enter the azure user_principal_id Variable : 
 EX: 67bf46cc-38ec-4f23-aba7-fedfcde26856
---> Enter the Workspace_key Variable : 
 EX: devBabyAsset
---> Enter the azure team_id Variable : 
 EX: 25d59980-4644-4ba0-af6f-2ce9fae86c96
---> Enter the acr simulator_repository Variable : 
 EX: simulator_simulator
---> Enter the acr simulator_version Variable : 
 EX: ASSET_5555fc9d_2023-08-03-10h29-09Z
---> Enter the azure function_artifact_url Variable : 
 EX: https://github.com/Cosmo-Tech/supplychain-azure-function-dataset-download/releases/download/2.1.10/artifact.zip
https://github.com/Cosmo-Tech/supplychain-azure-function-dataset-download/releases/download/2.1.10/artifact.zip
---> Enter the webapp deployment_name Variable : 
 EX: devasset
---> Enter the webapp location Variable : 
 EX: eastus2
---> Enter the github organization Variable for github deployement :
 EX: Cosmo-Tech
---> Enter the github repository Variable for github deployement :
 EX: azure-webapp-asset-qa
azure-webapp-asset-qa
---> Enter the github branch Variable for github deployement : 
 EX: bash/asset
bash/asset
---> Enter the github repository Variable to retrieve the GitHub webapp :
 EX: phoenix-asset-product-webapp
phoenix-asset-product-webapp
---> Enter the github branch Variable to retrieve the GitHub webapp :
 EX: deployment/dev1
deployment/dev1
---> Enter the github token Variable to authenticate for the GitHub repository :
 EX:You should generate a token
---> Enter the api url version Variable : 
 EX: https://dev.api.cosmotech.com/v2-4-dev
https://dev.api.cosmotech.com/v2-4-dev
-----> Please set all paths to dataset|ADX|powerbi: 
---> Enter the PATH to ADX : 
 EX: /home/user/deploy/ADX/
/home/user/cosmotech/my_scripte/babylon_install/adx/
---> Enter the PATH to powerbi_dashboard_view : 
 EX: /home/user/deploy/powerbi/dashboard/
/home/user/cosmotech/my_scripte/babylon_install/powerbi/dashboard/
---> Enter the PATH to powerbi_scenario_view : 
 EX: /home/user/deploy/powerbi/scenario/
/home/user/cosmotech/my_scripte/babylon_install/powerbi/scenario/
---> Enter the PATH to DATASET(.csv) : 
 EX: /home/user/deploy/DATASET/
/home/user/cosmotech/my_scripte/babylon_install/dataset/
---> Enter the PATH to asset.dev.solution : 
 EX: /home/user/deploy/PAYLOAD/
/home/user/cosmotech/my_scripte/babylon_install/
---> Enter the type of connector and dataset you want : 
 EX: twin or storage or adt
storage
---> Enter the version of connector you want : 
 EX: 1.1.2
1.1.2
```


