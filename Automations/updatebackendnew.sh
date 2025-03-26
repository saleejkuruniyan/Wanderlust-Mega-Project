#!/bin/bash

# Get the name of one of the nodes in AKS (e.g., the first node)
NODE_NAME=$(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}')

# Retrieve the external IP of the node (assuming it has one)
ipv4_address=$(kubectl get node $NODE_NAME -o=jsonpath='{.status.addresses[?(@.type=="ExternalIP")].address}')

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
