#!/bin/bash

# Define your AKS cluster and resource group
RESOURCE_GROUP=$1
CLUSTER_NAME=$2

NODE_RG=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)

VMSS_NAME=$(az vmss list --resource-group $NODE_RG --query "[].name" -o tsv)

ipv4_address=$(az vmss list-instance-public-ips \
  --resource-group $NODE_RG \
  --name $VMSS_NAME \
  --query "[].ipAddress" -o tsv | head -n 1)

# Exit if ipv4_address is empty
if [[ -z "$ipv4_address" ]]; then
    echo "ERROR: No external IP found for node $NODE_NAME."
    exit 1
fi

# Path to the .env file
file_to_find="../backend/.env.docker"

# Check the current FRONTEND_URL in the .env file
current_url=$(sed -n "4p" $file_to_find)

# Update the .env file if the IP address has changed
if [[ "$current_url" != "FRONTEND_URL=\"http://${ipv4_address}:5173\"" ]]; then
    if [ -f $file_to_find ]; then
        sed -i -e "s|FRONTEND_URL.*|FRONTEND_URL=\"http://${ipv4_address}:5173\"|g" $file_to_find
    else
        echo "ERROR: File not found."
    fi
fi
