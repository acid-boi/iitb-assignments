#!/bin/bash

#I have just tried to create a basic port scanner which tries sending hello to each port listed, but before that tries to ping to check if the host is active
#prips tool must be installed on the system. This is used to list the ips present in the cidr subnet provided.
#Can be installed using sudo apt install prips

ip=$1 #storing the command line arguments into the corresponding fields
min=$2
max=$3
cidr=$4

#Checking if the correct number of parameters are provided
if [ $# -lt 4 ]; then
    echo "Usage ./scanner <target IP> <lowerbound port> <higherbound port> <CIDR indicator(1 if subnet, 0 for ip)>"
    exit
fi
scan() {
    #Function to first ping the host of the given ip to check if its reachable and then try to create connetions with its ports
    #However some hosts block the ping requests but that is an advanced networking concept. For this project i am not considering
    #edge cases
    ping -c 1 $1 >/dev/null 2>&1
    status=$?

    if [ $status -ne 0 ]; then
        echo "The host is not reachable! Please provide another host"
    fi

    for i in $(seq $(($2 - 1)) $3); do
        timeout 1 bash -c "echo hello > /dev/tcp/$ip/$i " >/dev/null 2>&1
        statusCode=$?
        if [ $statusCode -eq 0 ]; then
            echo "Port $i is open for the host $ip"
        fi
    done
}
ips=() # array for storing the ips if multiple or single ip
if [ $cidr -eq 0 ]; then
    ips+=("$ip")
else
    prips $ip >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ips=($(prips $ip))
    else
        echo -e "Please provide ip in the right format.(Make sure the ip provided is the beginning of the subnet!)\n"
        exit
    fi
fi

for address in "${ips[@]}"; do #Iterating through the IPs and scanning them one by one
    echo -e "Trying to enumerate the ip $address \n"
    scan $address $min $max
done
