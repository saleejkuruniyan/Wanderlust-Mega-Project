#!/bin/bash

# Define your AKS cluster and resource group
RESOURCE_GROUP="WanderlustResourceGroup"
CLUSTER_NAME="wanderlust"

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
file_to_find="../frontend/.env.docker"

# Check the current VITE_API_PATH in the .env file
current_url=$(cat $file_to_find)

# Update the .env file if the IP address has changed
if [[ "$current_url" != "VITE_API_PATH=\"http://${ipv4_address}:31100\"" ]]; then
    if [ -f $file_to_find ]; then
        sed -i -e "s|VITE_API_PATH.*|VITE_API_PATH=\"http://${ipv4_address}:31100\"|g" $file_to_find
    else
        echo "ERROR: File not found."
    fi
fi
