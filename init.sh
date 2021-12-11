#!/bin/bash

echo "Defining variables..."
export RESOURCE_SUFFIX="glm"
export RESOURCE_GROUP_NAME=mslearn-gh-pipelines-$RESOURCE_SUFFIX
export AKS_NAME=contoso-video
export ACR_NAME=ContosoContainerRegistry$RESOURCE_SUFFIX
export LOCATION=eastus

echo "Searching for resource group..."
az group create -n $RESOURCE_GROUP_NAME -l $LOCATION

echo "Creating cluster..."
az aks create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $AKS_NAME \
  --node-count 1 \
  --enable-addons http_application_routing \
  --dns-name-prefix $AKS_NAME \
  --enable-managed-identity \
  --generate-ssh-keys \
  --node-vm-size Standard_B2s

echo "Obtaining credentials..."
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP_NAME

echo "Creating ACR..."
az acr create -n $ACR_NAME -g $RESOURCE_GROUP_NAME --sku basic
az acr update -n $ACR_NAME --admin-enabled true

export ACR_USERNAME=$(az acr credential show -n $ACR_NAME --query "username" -o tsv)
export ACR_PASSWORD=$(az acr credential show -n $ACR_NAME --query "passwords[0].value" -o tsv)

az aks update \
    --name $AKS_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --attach-acr $ACR_NAME

export DNS_NAME=$(az network dns zone list -o json --query "[?contains(resourceGroup,'$RESOURCE_GROUP_NAME')].name" -o tsv)

sed -i '' 's+!IMAGE!+'"$ACR_NAME"'/contoso-website+g' kubernetes/deployment.yaml
sed -i '' 's+!DNS!+'"$DNS_NAME"'+g' kubernetes/ingress.yaml

echo "Installation concluded, copy these values and store them, you'll use them later in this exercise:"

echo "-> Resource Group Name: $RESOURCE_GROUP_NAME" 
#mslearn-gh-pipelines-glm
echo "-> ACR Name: $ACR_NAME"
#contosocontainerregistryglm.azurecr.io
echo "-> ACR Login Username: $ACR_USERNAME"
#ContosoContainerRegistryglm
echo "-> ACR Password: $ACR_PASSWORD"
#gzkrC=kxGWgMw8+n1ph8X3o0175SX7/5
echo "-> AKS Cluster Name: $AKS_NAME"
#contoso-video
echo "-> AKS DNS Zone Name: $DNS_NAME"
#contoso.320e7a3489b04980aa9f.eastus.aksapp.io
