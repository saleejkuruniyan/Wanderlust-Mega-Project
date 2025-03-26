#!/bin/bash

# Define your AKS cluster and resource group
RESOURCE_GROUP="WanderlustResourceGroup"
CLUSTER_NAME="wanderlust"

# Get the name of one of the nodes (e.g., the first node)
NODE_NAME=$(az aks nodepool list --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --query '[0].name' -o tsv)

# Retrieve the node resource group (AKS creates a separate node resource group)
NODE_RESOURCE_GROUP=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "nodeResourceGroup" -o tsv)

# Get the external IP of the first VM in the node pool
ipv4_address=$(az network public-ip list --resource-group $NODE_RESOURCE_GROUP --query "[?ipAddress!=null].ipAddress" -o tsv | head -n 1)

# Exit if ipv4_address is empty
if [[ -z "$ipv4_address" ]]; then
    echo "ERROR: No external IP found for node $NODE_NAME."
    exit 1
fi

ipv4_address="172.190.57.137"

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
