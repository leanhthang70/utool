#!/bin/bash

echo "SSH Key Generation Script"
echo "=========================="
echo "1) Tạo SSH key mới và thêm vào config"
echo "   - Tạo một cặp SSH key mới (ed25519/rsa/ecdsa), cho phép đặt tên file, passphrase, comment/email."
echo "   - Tự động thêm cấu hình Host vào ~/.ssh/config cho key vừa tạo."
echo "2) Thêm config cho tất cả các key hiện có trong ~/.ssh (nếu chưa có)"
echo "   - Quét tất cả các file private key trong ~/.ssh (id_*, *.pem, *.ed25519, *.rsa, *.ecdsa, ...)."
echo "   - Nếu chưa có entry Host tương ứng trong ~/.ssh/config thì sẽ tự động thêm vào."
echo "3) Thoát"
echo
read -p "=> Chọn option [1-3]: " main_option

if [ "$main_option" = "1" ]; then
    echo "Select key type:"
    echo "1) ed25519 (recommended)"
    echo "2) rsa"
    echo "3) ecdsa"
    read -p "=> Enter option [1-3]: " key_option

    case $key_option in
        1)
            key_type="ed25519"
            ;;
        2)
            key_type="rsa"
            ;;
        3)
            key_type="ecdsa"
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac

    read -p "=> Enter your email/comment: " email
    read -p "=> Enter key file name (default: id_${key_type}): " keyfile
    keyfile=${keyfile:-id_${key_type}}
    keypath="$HOME/.ssh/$keyfile"
    
    # Check if key already exists
    if [ -f "$keypath" ]; then
        read -p "Key $keyfile already exists. Overwrite? [y/N]: " overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            echo "Cancelled."
            exit 0
        fi
    fi
    
    read -s -p "=> Enter passphrase (leave empty for no passphrase): " passphrase
    echo

    echo "Generating SSH key..."
    if [ -z "$passphrase" ]; then
        ssh-keygen -t $key_type -C "$email" -f "$keypath" -N ""
    else
        ssh-keygen -t $key_type -C "$email" -f "$keypath" -N "$passphrase"
    fi


    echo "Configuring ~/.ssh/config..."
    host_name="${keyfile}"
    read -p "=> Nhập HostName (IP hoặc domain): " input_hostname
    if [ -z "$input_hostname" ]; then
        echo "HostName không được để trống. Bỏ qua việc tạo config."
    else
        hostname_value="$input_hostname"
        
        # Ask for User only if needed
        default_user=""
        user_config=""
        if [[ "$hostname_value" == *"github.com"* ]] || [[ "$hostname_value" == *"gitlab.com"* ]]; then
            default_user="git"
            echo "Detected Git hosting service. Using default user: git"
            user_config="    User git"        
        if ! grep -q "^Host $host_name$" "$HOME/.ssh/config" 2>/dev/null; then
            cat <<EOF >> $HOME/.ssh/config

Host $host_name
    HostName $hostname_value
$user_config
    IdentityFile ~/.ssh/$keyfile
    IdentitiesOnly yes
EOF
            echo "Config entry added for Host: $host_name (HostName: $hostname_value)"
        else
            echo "Config entry for Host: $host_name already exists."
        fi
    fi

    echo "Done!"
    echo "Key saved to $keypath"
    echo "Public key:"
    cat "$keypath.pub"
    echo
    echo "To add this key to GitHub/GitLab, copy the above public key."

elif [ "$main_option" = "2" ]; then
    echo "Scanning ~/.ssh for private keys..."
    config_file="$HOME/.ssh/config"
    mkdir -p "$HOME/.ssh"
    touch "$config_file"
    chmod 600 "$config_file"
    
    # Find all potential private key files by excluding known non-key files
    found_keys=false
    for keyfile in $(find "$HOME/.ssh" -maxdepth 1 -type f ! -name "*.pub" ! -name "config" ! -name "known_hosts*" ! -name "*_known_hosts"); do
        key=$(basename "$keyfile")
        # Check if it's actually a private key by looking for "PRIVATE KEY" string
        if grep -q "PRIVATE KEY" "$keyfile" 2>/dev/null; then
            echo "Found private key: $key"
            found_keys=true
            host_name="${key}"
            if ! grep -q "^Host $host_name$" "$config_file"; then
                read -p "=> Nhập HostName cho Host $host_name: " input_hostname
                if [ -z "$input_hostname" ]; then
                    echo "HostName không được để trống. Bỏ qua key: $key"
                    continue
                fi
                hostname_value="$input_hostname"
                
                # Ask for User only if needed
                user_config=""
                if [[ "$hostname_value" == *"github.com"* ]] || [[ "$hostname_value" == *"gitlab.com"* ]]; then
                    echo "Detected Git hosting service. Using default user: git"
                    user_config="    User git"
                else
                    read -p "=> Nhập User cho Host $host_name (Enter để bỏ qua): " input_user
                    if [ -n "$input_user" ]; then
                        user_config="    User $input_user"
                    fi
                fi
                
                cat <<EOF >> "$config_file"

Host $host_name
    HostName $hostname_value
$user_config
    IdentityFile ~/.ssh/$key
    IdentitiesOnly yes
EOF
                echo "✓ Added config for Host: $host_name (HostName: $hostname_value)"
            else
                echo "- Config for Host: $host_name already exists."
            fi
        fi
    done
    
    if [ "$found_keys" = false ]; then
        echo "No private keys found in ~/.ssh/"
    else
        echo "Done! Config file updated."
    fi
elif [ "$main_option" = "3" ]; then
    echo "Exiting..."
    exit 0
else
    echo "Invalid option. Exiting."
    exit 1
fi
