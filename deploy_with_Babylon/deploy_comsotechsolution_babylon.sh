#!/usr/bin/sh

# Variables de couleur pour l'affichage
cl_red="\033[1;31m"
cl_green="\033[1;32m"
cl_blue="\033[1;34m"
cl_yellow="\033[1;33m"
cl_grey="\033[1;37m"
cl_df="\033[0;m"

if [ $# -lt 2 ]; then
  echo "[$cl_red ERROR $cl_df] Missing parameters !!"
  echo "[$cl_red ERROR $cl_df] Usage:$cl_grey source $cl_df./install_asset.sh <solution> <platform>"
  echo "[$cl_red ERROR $cl_df] Example:$cl_grey source $cl_df./install_asset.sh asset dev"
else

# Function to display an animated spinner
spinner() {
	local pid=$1
	local delay=0.5
	local spinstr='|/-\'
	while ps -p $pid > /dev/null; do
		for i in ${spinstr}; do
			echo -ne "\rInstalling dependencies... ${i}"
			sleep ${delay}
		done
		echo -ne "\r\033[K" 
	done
	echo -e "\r\033[KInstalling dependencies... Done"
}

# Function to install Babylon
install_package() {
	if [ $# != 1 ]
	then
		echo "[$cl_red-$cl_df] You need to give one argument for : $cl_purple install_package$cl_df"
	else
	  echo "[$cl_green+$cl_df] Starting the installation of : $cl_yellow$cl_cyan $1 $cl_df"
      git clone git@github.com:Cosmo-Tech/Babylon.git > /dev/null
	  cd Babylon
      activate_venv() {
        . .venv/bin/activate
      }
      python3 -m venv .venv
      activate_venv
	 (pip install -e . > /dev/null) &
	  # Capture the PID of the background process
	  pip_pid=$!
      # Start the spinner
	  spinner $pip_pid
		if [ $? = 0 ]
		then
			echo "[$cl_green+$cl_df] $cl_green Successful installation$cl_df of $cl_yellow$cl_cyan$1$cl_df"
		else
			echo "[$cl_red-$cl_df] $cl_cyan$1$cl_df : $cl_red Installation failed$cl_df"
			kill -INT $$
		fi
	fi
}
echo "[$cl_green + OK $cl_df] Syntax correct. $cl_blue Welcome to the deployment the solution $1 with $cl_df$cl_yellow Babylon$cl_df"
#Babylon Dev mode installation
echo
echo "------------------------------------------Babylon Dev mode installation---------------------------------------"
install_package "Babylon"
babylon
echo
echo "-------> $cl_yellow Setup environment variables$cl_df"
echo "-----> We have 4 required environment variables for Babylon Works:"
echo "---> Enter the$cl_grey BABYLON_SERVICE$cl_df Variable : " 
echo "$cl_green EX$cl_df: https://engineering.uksouth.cloudapp.azure.com/" 
read BABYLON_SERVICE
echo "---> Enter the$cl_grey BABYLON_TOKEN$cl_df Variable : " 
echo "$cl_green EX$cl_df: Contact the Cloud team" 
read BABYLON_TOKEN
echo "---> Enter the$cl_grey BABYLON_ORG_NAME$cl_df Variable : " 
echo "$cl_green EX$cl_df: cosmotech"
read BABYLON_ORG_NAME
echo "---> Enter the$cl_grey BABYLON_ENCODING_KEY$cl_df Variable : " 
echo "Took a look at the document of Babylon" 
echo "$cl_green EX$cl_df: babylon azure token store -c brewery -p perf --scope powerbi"
read BABYLON_ENCODING_KEY
echo "-----> We can set all the necessary environment variables for your solution $1:"
echo "---> Enter Your$cl_grey Email$cl_df Variable : " 
echo "$cl_green EX$cl_df: user@cosmotech.com" 
read Email
echo "---> Enter the azure$cl_grey user_principal_id$cl_df Variable : "
echo "$cl_green EX$cl_df: 67bf46cc-38ec-4f23-aba7-fedfcde26856" 
read user_principal_id
echo "---> Enter the$cl_grey Workspace_key$cl_df Variable : "
echo "$cl_green EX$cl_df: devBabyAsset"  
read workspace_key
echo "---> Enter the azure$cl_grey team_id$cl_df Variable : "
echo "$cl_green EX$cl_df: 25d59980-4644-4ba0-af6f-2ce9fae86c96"  
read team_id
echo "---> Enter the acr$cl_grey simulator_repository$cl_df Variable : " 
echo "$cl_green EX$cl_df: simulator_simulator"
read simulator_repository
echo "---> Enter the acr$cl_grey simulator_version$cl_df Variable : " 
echo "$cl_green EX$cl_df: ASSET_5555fc9d_2023-08-03-10h29-09Z"
read simulator_version
echo "---> Enter the azure$cl_grey function_artifact_url$cl_df Variable : " 
echo "$cl_green EX$cl_df: https://github.com/Cosmo-Tech/supplychain-azure-function-dataset-download/releases/download/2.1.10/artifact.zip"
read function_artifact_url
echo "---> Enter the webapp$cl_grey deployment_name$cl_df Variable : " 
echo "$cl_green EX$cl_df: devasset"
read deployment_name
echo "---> Enter the webapp$cl_grey location$cl_df Variable : " 
echo "$cl_green EX$cl_df: eastus2"
read location
echo "---> Enter the github$cl_grey organization$cl_df Variable for github deployement :" 
echo "$cl_green EX$cl_df: Cosmo-Tech"
read organization
echo "---> Enter the github$cl_grey repository$cl_df Variable for github deployement :" 
echo "$cl_green EX$cl_df: azure-webapp-asset-qa"
read repository_D
echo "---> Enter the github$cl_grey branch$cl_df Variable for github deployement : " 
echo "$cl_green EX$cl_df: dev/asset"
read branch_D
echo "---> Enter the github$cl_grey repository$cl_df Variable to retrieve the GitHub webapp :" 
echo "$cl_green EX$cl_df: phoenix-asset-product-webapp"
read repository_R
echo "---> Enter the github$cl_grey branch$cl_df Variable to retrieve the GitHub webapp :"
echo "$cl_green EX$cl_df: upstream/deployment/dev1" 
read branch_R
echo "---> Enter the github$cl_grey token$cl_df Variable to authenticate for the GitHub repository :"
echo "$cl_green EX$cl_df:You should generate a token" 
read pat
echo "---> Enter the api$cl_grey url$cl_df version Variable : " 
echo "$cl_green EX$cl_df: https://dev.api.cosmotech.com/v2-4-dev" 
read url
echo "-----> Please set all paths to$cl_grey dataset|ADX|powerbi$cl_df: "
echo "---> Enter the PATH to$cl_grey ADX$cl_df : "
echo "$cl_green EX$cl_df: /home/user/deploy/ADX/"
read ADX_R
echo "---> Enter the PATH to$cl_grey powerbi_dashboard_view$cl_df : "
echo "$cl_green EX$cl_df: /home/user/deploy/powerbi/dashboard/"
read powerbi_dashboard_view_R
echo "---> Enter the PATH to$cl_grey powerbi_scenario_view$cl_df : "
echo "$cl_green EX$cl_df: /home/user/deploy/powerbi/scenario/"
read powerbi_scenario_view_R
echo "---> Enter the PATH to$cl_grey DATASET(.csv)$cl_df : "
echo "$cl_green EX$cl_df: /home/user/deploy/DATASET/"
read DATASET_R
echo "---> Enter the PATH to$cl_grey asset.dev.solution$cl_df : "
echo "$cl_green EX$cl_df: /home/user/deploy/PAYLOAD/"
read PAYLOAD_R
echo "---> Enter the type of$cl_grey connector and dataset$cl_df you want : " 
echo "$cl_green EX$cl_df: twin or storage or adt"
read type 
echo "---> Enter the version of$cl_grey connector$cl_df you want : " 
echo "$cl_green EX$cl_df: 1.1.2"
read version_R
echo
#Export the necessary environment variables
echo "------------------------------------------Export the necessary environment variables---------------------------------------"
echo 
export BABYLON_SERVICE=$BABYLON_SERVICE
export BABYLON_TOKEN=$BABYLON_TOKEN
export BABYLON_ORG_NAME=$BABYLON_ORG_NAME
export BABYLON_ENCODING_KEY=$BABYLON_ENCODING_KEY

#Retrieve dev platform configuration
babylon config init -c $1 -p $2 

#Setup environment variables
echo "------------------------------------------Setup environment variables---------------------------------------"
echo 
babylon config set azure email $Email -c $1 -p $2
babylon config set azure user_principal_id $user_principal_id -c $1 -p $2
babylon config set api workspace_key $workspace_key -c $1 -p $2
babylon config set powerbi dashboard_view -c $1 -p $2
babylon config set azure team_id $team_id -c $1 -p $2
babylon config set acr simulator_repository $simulator_repository -c $1 -p $2
babylon config set acr simulator_version $simulator_version -c $1 -p $2
babylon config set azure function_artifact_url $function_artifact_url -c $1 -p $2
babylon config set webapp deployment_name $deployment_name_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 4) -c $1 -p $2
babylon config set webapp location $location -c $1 -p $2
babylon config set github branch $branch_D -c $1 -p $2
babylon config set github organization $organization -c $1 -p $2
babylon config set github repository $repository_D -c $1 -p $2
babylon config set api run_templates -c $1 -p $2 --item "common"
babylon config set api url $url -c $1 -p $2
echo
#create a new organization
echo "-------------------------------------------create a new organization------------------------------------------"
echo 
babylon api organizations payload create -c $1 -p $2
babylon api organizations create $1-Org_Cosmo_Tech -c $1 -p $2
babylon api organizations security add -c $1 -p $2 --email $Email --role admin
echo
# #create container storage by default
echo "-------------------------------------------create container storage by default------------------------------------------"
echo 
organization_id=$(babylon config get -c $1 -p $2 api organization_id)
babylon azure storage container create $organization_id  -c $1 -p $2
babylon azure iam set -c $1 -p $2 --resource-type "Microsoft.Storage/storageAccounts" --role-id %azure%storage_blob_reader --principal-id %azure%team_id --principal-type Group --resource-name %azure%storage_account_name
babylon azure iam set -c $1 -p $2 --resource-type "Microsoft.Storage/storageAccounts" --role-id %azure%storage_blob_reader --principal-id %platform%principal_id --resource-name %azure%storage_account_name
echo
#deploy adx database and permissions
echo "-----------------------------------------deploy adx database and permissions-----------------------------------"
echo 
ADX=$ADX_R
babylon azure adx database create -c $1 -p $2
babylon azure adx permission set -c $1 -p $2 --principal-type User --role Admin %azure%user_principal_id  
babylon azure adx permission set -c $1 -p $2 --principal-type Group --role Admin %azure%team_id
babylon azure adx permission set -c $1 -p $2 --principal-type App --role Admin %platform%principal_id
babylon azure adx script run-folder $ADX -c $1 -p $2
echo
#deploy eventhub namespaces and permissions
echo "----------------------------------------deploy eventhub namespaces and permissions------------------------------------"
echo 
babylon azure arm run $1-Eventhub_Deploy -c $1 -p $2 --file %templates%/arm/eventhub_deploy.json 
babylon azure iam set -c $1 -p $2 --resource-type Microsoft.EventHub/Namespaces --role-id %azure%eventhub_built_data_receiver --principal-id %adx%cluster_principal_id
babylon azure iam set -c $1 -p $2 --resource-type Microsoft.EventHub/Namespaces --role-id %azure%eventhub_built_data_sender --principal-id %platform%principal_id
babylon azure iam set -c $1 -p $2 --resource-type Microsoft.EventHub/Namespaces --role-id %azure%eventhub_built_data_sender --principal-id %babylon%principal_id
babylon azure iam set -c $1 -p $2 --principal-id %azure%team_id  --principal-type Group --resource-type Microsoft.EventHub/Namespaces --role-id %azure%eventhub_built_contributor_id
babylon azure adx consumer add "adx" "ProbesMeasures" -c $1 -p $2
babylon azure adx consumer add "adx" "ScenarioMetaData" -c $1 -p $2
babylon azure adx consumer add "adx" "ScenarioRun" -c $1 -p $2
babylon azure adx consumer add "adx" "ScenarioRunMetaData" -c $1 -p $2 
babylon azure adx connections create -c $1 -p $2  ProbesMeasures %adx%database_name --data-format JSON --table-name ProbesMeasures --compression GZip  --consumer-group adx --mapping ProbesMeasuresMapping
babylon azure adx connections create -c $1 -p $2  ScenarioMetaData %adx%database_name --data-format CSV --table-name ScenarioMetadata --consumer-group adx --mapping ScenarioMetadataMapping
babylon azure adx connections create -c $1 -p $2  ScenarioRun %adx%database_name --data-format JSON --table-name SimulationTotalFacts --consumer-group adx --mapping SimulationTotalFactsMapping
babylon azure adx connections create -c $1 -p $2  ScenarioRunMetaData %adx%database_name  --data-format CSV --table-name ScenarioRunMetadata --consumer-group adx --mapping ScenarioRunMetadataMapping
echo
#Authentication Eventhub configuration
echo "-------------------------------------------------Authentication Eventhub configuration----------------------------------"
echo 
database_name=$(babylon config get -c $1 -p $2 adx database_name) 
eventkey=$(az eventhubs namespace authorization-rule keys list -g phoenixdev --namespace-name $database_name --name RootManageSharedAccessKey --query primaryKey)
babylon hvac set project eventhub $eventkey -c $1 -p $2
echo
#deploy workspace powerbi
echo "--------------------------------------------------deploy workspace powerbi-------------------------------------------------"
echo 
powerbi_dashboard_view=$powerbi_dashboard_view_R
powerbi_scenario_view=$powerbi_scenario_view_R
babylon powerbi workspace deploy $1-dashboard_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 4) -c $1 -p $2 --type dashboard_view --folder $powerbi_dashboard_view/ --override
babylon powerbi workspace deploy $1-scenario_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 4) -c $1 -p $2 --type scenario_view  --folder $powerbi_scenario_view/ --override  
echo
#retrieve sample webapp
echo "------------------------------------------------retrieve sample webapp------------------------------------------------"
git config --global pull.rebase true
git config --global init.defaultBranch main
name=bashwebapp_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 2)
mkdir $name
cd $name
git init
echo "# empty_webapp" >> README.md
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://Cosmo-Tech:$pat@github.com/Cosmo-Tech/$repository_D.git
git remote add upstream https://oauth2:$pat@github.com/Cosmo-Tech/$repository_R.git
git remote set-url upstream --push "NO"
git fetch --all --tags --prune
git checkout -B $branch_D $branch_R
rm -r .github/
git add .; git commit -m 'first commit'
git push origin $branch_D -f
cd ..
echo
#deploy webapp
echo "-------------------------------------------------deploy webapp----------------------------------------------------"
echo 
babylon webapp deploy -c $1 -p $2 --with-azf 
babylon powerbi workspace user add -c $1 -p $2 %app%principal_id App Admin
babylon azure iam set -c $1 -p $2 --resource-type Microsoft.EventHub/Namespaces --role-id %azure%eventhub_built_data_sender --principal-id %app%principal_id 
echo
#Retrieve azure function key
echo "-------------------------------------------------Retrieve azure function key----------------------------------------------------"
echo  
database_name=$(babylon config get -c $1 -p $2 adx database_name)
azf_key=$(az functionapp keys list -g phoenixdev -n $database_name --query masterKey)
babylon hvac set project func $azf_key -c $1 -p $2
echo  
#create a connector and database
case "$type" in
  "twin")
    echo "---> You selected $cl_grey'twin'$cl_df. Performing actions for 'twin'..."
    #create connector twin
    echo "---------------------------------------------create connector $type----------------------------------------------"
    echo 
    babylon api connectors payload create -c $1 -p $2 --type $type
    babylon api connectors create $1-Baby_Connector_TWIN -c $1 -p $2 --type $type --version $version_R
    #create dataset twin
    echo "--------------------------------------------------create dataset $type-------------------------------------------"
    echo 
    babylon api datasets payload create -c $1 -p $2 --type $type
    babylon api datasets create $1-Baby_dataset_TWIN -c $1 -p $2 --type $type 
    ;;
  "storage")
    echo "--> You selected $cl_grey'storage'$cl_df. Performing actions for 'storage'..."
    #create connector storage
    echo "---------------------------------------------create connector $type----------------------------------------------"
    echo 
    babylon api connectors payload create -c $1 -p $2 --type $type
    babylon api connectors create $1-Baby_Connector_STORAGE -c $1 -p $2 --type $type --version $version_R
    #create dataset storage
    echo "--------------------------------------------------create dataset $type-------------------------------------------"
    echo 
    babylon api datasets payload create -c $1 -p $2 --type $type
    babylon api datasets create $1-Baby_dataset_STORAGE -c $1 -p $2 --type $type 
    ;;
    "adt")
    echo "--> You selected $cl_grey'adt'$cl_df. Performing actions for 'adt'..."
    #create connector adt
    echo "---------------------------------------------create connector $type----------------------------------------------"
    echo 
    babylon api connectors payload create -c $1 -p $2 --type $type
    babylon api connectors create $1-Baby_Connector_ADT -c $1 -p $2 --type $type --version $version_R
    #create dataset adt
    echo "--------------------------------------------------create dataset $type-------------------------------------------"
    echo 
    babylon api datasets payload create -c $1 -p $2 --type $type
    babylon api datasets create $1-Baby_dataset_ADT -c $1 -p $2 --type $type 
    ;;
  *)
    echo "Invalid type. Please enter $cl_grey'twin'$cl_df or $cl_grey'storage'$cl_df or $cl_grey'adt'$cl_df."
    ;;
esac
echo
Add content to runTemplates field
PAYLOAD=$PAYLOAD_R
cp $PAYLOAD_R/*.yaml  ./.payload/
#create solution Asset
echo "---------------------------------------------------create solution $1-----------------------------------------------"
echo 
babylon api solutions create $1-Solution_Deploy -c $1 -p $2
echo
#create workspace Asset
echo "-----------------------------------------------------create workspace $1---------------------------------------------"
echo 
babylon api workspaces payload create -c $1 -p $2
babylon api workspaces create $1-Baby_Workspace -c $1 -p $2
babylon api workspaces security add -c $1 -p $2 --email $Email --role admin
babylon api workspaces send-key -c $1 -p $2
echo
#upload CSV file asset
echo "-----------------------------------------------------upload CSV file $1--------------------------------------------"
echo 
DATASET=$DATASET_R
babylon azure storage container upload -c $1 -p $2 --folder $DATASET
fi