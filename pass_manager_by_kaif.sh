#!/bin/bash

PASSWORD_DIR="$HOME/.password_manager"
PASSWORD_FILE="$PASSWORD_DIR/passwords.txt"
VERIFICATION_CODE="150180" 


if [ ! -d "$PASSWORD_DIR" ]; then
    mkdir -p "$PASSWORD_DIR"
    chmod 700 "$PASSWORD_DIR"
fi

if [ ! -e "$PASSWORD_FILE" ]; then
    touch "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
fi


read -p "Enter the code to access the password Manager: " user_verification_code

if [ "$user_verification_code" == "$VERIFICATION_CODE" ]; then

    chattr +i "$PASSWORD_FILE"
    
    echo -e "\nVerification successful. Access granted."

else
    echo -e "\nInvalid verification code. Access denied."
    exit 1
fi


encrypt_password() {
    echo "$1" | openssl enc -aes-256-cbc -a -salt -pass pass:secretpassword
}


decrypt_password() {
    echo "$1" | openssl enc -d -aes-256-cbc -a -pass pass:secretpassword
}


add_password() {
    read -p "Enter the username: " service
    read -s -p "Enter the password: " password
    encrypted_password=$(encrypt_password "$password")
    echo "$service: $encrypted_password" >> "$PASSWORD_FILE"
    echo -e "\nPassword added for $service."
}


get_password() {
    read -p "Enter the username for the password: " service
    read -p "Enter the passcode to see the password: " verification_code

    if [ "$verification_code" == "150180" ]; then
        encrypted_password=$(grep "^$service:" "$PASSWORD_FILE" | cut -d' ' -f2)

        if [ -n "$encrypted_password" ]; then
            decrypted_password=$(decrypt_password "$encrypted_password")
  
            echo -e "\nPassword for $service: $decrypted_password"
        else
            echo -e "\nPassword not found for $service."
        fi
    else
        echo -e "\nInvalid code. Access denied."
    fi
}


list_services() {
    echo -e "\nList of Services:"
    awk -F ':' '{print $1}' "$PASSWORD_FILE"
}


update_password() {
    read -p "Enter the username that you want to update: " service
    read -p "Enter the verification code: " verification_code

    if [ "$verification_code" == "150180" ]; then
        encrypted_password=$(grep "^$service:" "$PASSWORD_FILE" | cut -d' ' -f2)

        if [ -n "$encrypted_password" ]; then
            read -s -p "Enter the new password: " new_password
            updated_encrypted_password=$(encrypt_password "$new_password")
            sed -i "s|^$service:.*|$service: $updated_encrypted_password|" "$PASSWORD_FILE"
            echo -e "\nPassword updated for $service."
        else
            echo -e "\nService $service not found. You can add it using option 1."
        fi
    else
        echo -e "\nInvalid verification code. Access denied."
    fi
}


delete_password() {
    read -p "Enter the username that you want to delete: " service
    sed -i "/^$service:/d" "$PASSWORD_FILE"
    echo -e "\nPassword deleted for $service."
}


search_password() {
    read -p "Enter username to search: " service
    read -p "Enter the verification code: " verification_code

    if [ "$verification_code" == "150180" ]; then
        encrypted_password=$(grep "^$service:" "$PASSWORD_FILE" | cut -d' ' -f2)

        if [ -n "$encrypted_password" ]; then
            decrypted_password=$(decrypt_password "$encrypted_password")
            echo -e "\nPassword for $service: $decrypted_password"
        else
            echo -e "\nPassword not found for $service."
        fi
    else
        echo -e "\nInvalid verification code. Access denied."
    fi
}


while true; do
    echo -e "\nPassword Manager Menu:"
    echo "1. Add a new password"
    echo "2. Retrieve a password"
    echo "3. List all services"
    echo "4. Update a password"
    echo "5. Delete a password"
    echo "6. Search for a password"
    echo "7. Exit"

    read -p "Choose an option (1-7): " choice

    case $choice in
        1) add_password;;
        2) get_password;;
        3) list_services;;
        4) update_password;;
        5) delete_password;;
        6) search_password;;
        7) echo "Exiting Password Manager."; exit 0;;
        *) echo "Invalid option. Please choose a number between 1 and 7.";;
    esac
done

