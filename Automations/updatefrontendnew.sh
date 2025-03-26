#!/bin/bash

# Get the name of one of the nodes in AKS (e.g., the first node)
NODE_NAME=$(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}')

# Retrieve the external IP of the node (assuming it has one)
ipv4_address=$(kubectl get node $NODE_NAME -o=jsonpath='{.status.addresses[?(@.type=="ExternalIP")].address}')

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
