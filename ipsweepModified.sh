#!/bin/bash

# Check if the first argument is a valid IP address or network
if [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$ ]]; then
    network="${BASH_REMATCH[0]}"
else
    echo "Invalid IP address or network: $1"
    exit 1
fi

# Extract the network portion and network prefix from the provided IP address or network
IFS='/' read -ra parts <<< "$network"
network_portion="${parts[0]}"
network_prefix="${parts[1]:-24}"

# Validate the network prefix
if [[ $network_prefix -lt 1 || $network_prefix -gt 32 ]]; then
    echo "Invalid network prefix: $network_prefix"
    exit 1
fi

# Calculate the network and broadcast addresses
IFS='.' read -ra octets <<< "$network_portion"
network_address="$((octets[0] << 24 | octets[1] << 16 | octets[2] << 8 | octets[3]))"
broadcast_address="$((network_address | (2**(32-network_prefix)-1)))"

# Extract the last octet of the network address

last_octet=$((network_address & 255))

# Ping all hosts in the network range

for ((ip=$((last_octet+1)); ip<=$((broadcast_address&255)); ip++)); do
    ping -c 1 "${octets[0]}.${octets[1]}.${octets[2]}.$ip" | grep -q "64 bytes" && echo "${octets[0]}.${octets[1]}.${octets[2]}.$ip" $(ping -c 1 "${octets[0]}.${octets[1]}.${octets[2]}.$ip" | grep "time=" | cut -d "=" -f 4) &
done

wait
