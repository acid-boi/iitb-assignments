#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage ./softwarelab3.sh <target>"
    exit 1
fi

ip=$1
max_hops=20

for ttl in $(seq 1 $max_hops); do
    output=$(timeout 1 ping -c 1 -t $ttl $ip 2>&1)
    exitCode=$?

    if [ $exitCode -eq 0 ]; then
        hop=$(echo "$output" | grep -i "bytes from" | awk '{print $4}' | sed 's/$://')
        if [ -z "$hop" ]; then
            hop="$ip"
        fi
        echo "$ttl: $hop   (destination)"
        echo "Reached destination in $ttl hops."
        break
    else
        hop=$(echo "$output" | grep -i "From" | awk '{print $2}')
        if [ -z "$hop" ]; then
            hop="Couldn't resolve this host!"
        fi
        echo "$ttl: $hop"
    fi
done
