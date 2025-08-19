#!/bin/bash
# password_manager.sh

PASSFILE="/var/secure_passwords.txt"

add_password() {
    read -p "Enter service name: " service
    read -sp "Enter password: " password
    echo "$service:$password" | sudo tee -a "$PASSFILE" >/dev/null
    echo "Password saved."
}

list_passwords() {
    echo "Available services:"
    services=$(sudo cut -d ":" -f1 "$PASSFILE")
    select service in $services; do
        if [ -n "$service" ]; then
            password=$(sudo grep "^$service:" "$PASSFILE" | cut -d ":" -f2-)
            echo "You selected $service"
            echo "Choose an action:"
            echo "1) Copy to clipboard"
            echo "2) Print to terminal"
            echo "3) Export as environment variable"
            read -p "Option: " option

            if [ "$option" -eq 1 ]; then
                echo -n "$password" | xclip -selection clipboard 2>/dev/null ||
                    echo -n "$password" | pbcopy 2>/dev/null ||
                    echo "Clipboard tool not found!"
                echo "Password copied to clipboard (if supported)."
            elif [ "$option" -eq 2 ]; then
                echo "Password: $password"
            elif [ "$option" -eq 3 ]; then
                echo export "$service""_PASSWORD"="$password" >>~/.bashrc
                echo "Exported as $""$service""_PASSWORD, source the bashrc file to access"
            else
                echo "Invalid option."
            fi
            break
        else
            echo "Invalid selection"
        fi
    done
}

if [ "$1" = "add" ]; then
    add_password
elif [ "$1" = "list" ]; then
    list_passwords
else
    echo "Usage: $0 {add|list}"
fi
