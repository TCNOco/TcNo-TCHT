#!/bin/bash

echo -e "\033[36mI will try installing PowerShell now...\033[0m"

# IF LINUX:
if [[ "$(uname -s)" == "Linux" ]]; then
    # Check if Apt is available to install and use lsb-release to get OS information
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y lsb-release && apt-get clean all
        
        if [[ -f "/etc/lsb-release" ]]; then
            . /etc/lsb-release
            if [[ "$DISTRIB_ID" == "Ubuntu" ]]; then
                # Install PowerShell - https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.3
                # Install pre-requisite packages.
                apt-get install -y wget apt-transport-https software-properties-common
                # Download the Microsoft repository GPG keys
                wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
                # Register the Microsoft repository GPG keys
                dpkg -i packages-microsoft-prod.deb
                # Delete the the Microsoft repository GPG keys file
                rm packages-microsoft-prod.deb
                # Update the list of packages after we added packages.microsoft.com
                apt-get update
                # Install PowerShell
                apt-get install -y powershell
                # Start PowerShell
                pwsh
            elif [[ "$ID" == "debian" ]]; then
                # Install for Debian https://learn.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.3
                if [[ "$VERSION_ID" == "11" ]]; then
                    # Install system components
                    apt update  && apt install -y curl gnupg apt-transport-https

                    # Import the public repository GPG keys
                    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

                    # Register the Microsoft Product feed
                    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-bullseye-prod bullseye main" > /etc/apt/sources.list.d/microsoft.list'

                    # Install PowerShell
                    apt update && apt install -y powershell

                    # Start PowerShell
                    pwsh
                elif [[ "$VERSION_ID" == "10" ]]; then
                    # Download the Microsoft repository GPG keys
                    wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb

                    # Register the Microsoft repository GPG keys
                    dpkg -i packages-microsoft-prod.deb

                    # Update the list of products
                    apt-get update

                    # Install PowerShell
                    apt-get install -y powershell

                    # Start PowerShell
                    pwsh
                else
                    echo "This script is only for Debian 11 or Debian 10"
                fi
            elif [[ "$ID" == "raspbian" || "$ID" == "debian" ]]; then
                # Install for Raspbian https://learn.microsoft.com/en-us/powershell/scripting/install/install-raspbian?view=powershell-7.3
                if [[ "$VERSION_ID" =~ (9|10) ]]; then
                    # Prerequisites
                    apt-get update
                    apt-get install '^libssl1.0.[0-9]$' libunwind8 -y

                    # Download and extract PowerShell
                    wget https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/powershell-7.3.4-linux-arm32.tar.gz
                    mkdir ~/powershell
                    tar -xvf ./powershell-7.3.4-linux-arm32.tar.gz -C ~/powershell

                    # Start PowerShell
                    ~/powershell/pwsh
                fi
            fi
        else
            echo "Detected Linux, but could not install lsb-release using apt to check version information. See the following for more info:"
            echo "https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3"
        fi
    elif [[ -f "/etc/redhat-release" ]]; then
        # Install for RHEL https://learn.microsoft.com/en-us/powershell/scripting/install/install-rhel?view=powershell-7.3
        if grep -q "release 8" /etc/redhat-release; then
            # Register the Microsoft RedHat repository
            curl https://packages.microsoft.com/config/rhel/8/prod.repo | tee /etc/yum.repos.d/microsoft.repo

            # Install PowerShell
            dnf install --assumeyes powershell

            # Start PowerShell
            pwsh
        elif grep -q "release 7" /etc/redhat-release; then
            # Register the Microsoft RedHat repository
            curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo

            # Install PowerShell
            yum install --assumeyes powershell

            # Start PowerShell
            pwsh
        else
            echo "This script is only for RHEL 8 or RHEL 7"
        fi
    elif grep -q "Kali" /etc/os-release; then
        # Install for Kali https://learn.microsoft.com/en-us/powershell/scripting/install/community-support?view=powershell-7.3
        # Install PowerShell package
        apt update && apt -y install powershell

        # Start PowerShell
        pwsh
    elif [[ -f "/etc/alpine-release" ]]; then
        # Install for Alpine https://learn.microsoft.com/en-us/powershell/scripting/install/install-alpine?view=powershell-7.3
        # install the requirements
        apk add --no-cache ca-certificates less ncurses-terminfo-base krb5-libs libgcc libintl libssl1.1 libstdc++ tzdata userspace-rcu zlib icu-libs curl

        apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust

        # Download the powershell '.tar.gz' archive
        curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/powershell-7.3.4-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz

        # Create the target folder where powershell will be placed
        mkdir -p /opt/microsoft/powershell/7

        # Expand powershell to the target folder
        tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

        # Set execute permissions
        chmod +x /opt/microsoft/powershell/7/pwsh

        # Create the symbolic link that points to pwsh
        ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

        # Start PowerShell
        pwsh
    elif command -v snap >/dev/null 2>&1; then
        # Install with Snap: https://learn.microsoft.com/en-us/powershell/scripting/install/install-other-linux?view=powershell-7.3
        # Install PowerShell
        snap install powershell --classic

        # Start PowerShell
        pwsh
    else
        echo "Did not detect OS as supported Linux OS. Snap is also missing. See the following for more info:"
        echo "https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3"
    fi
fi
elif [[ "$(uname -s)" == "Darwin" ]]; then
    # ELSE FOR MAC
    if command -v brew >/dev/null 2>&1; then
        # Install PowerShell with Homebrew
        brew install --cask powershell

        # Start PowerShell
        pwsh
    else
        read -p "Homebrew is not installed. Do you want to install it? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Install Homebrew and PowerShell with Homebrew
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install --cask powershell

            # Start PowerShell
            pwsh
        else
            # Check if .NET Global is installed
            if command -v dotnet >/dev/null 2>&1; then
                # Install PowerShell with dotnet
                dotnet tool install --global PowerShell

                # Start PowerShell
                pwsh
            else
                # Check macOS architecture
                if [[ "$(uname -m)" == "x86_64" ]]; then
                    # Download PowerShell for x64 devices
                    curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/powershell-7.3.4-osx-x64.tar.gz
                else
                    # Download PowerShell for M1 devices
                    curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/powershell-7.3.4-osx-arm64.tar.gz
                fi

                # Create the target folder where PowerShell is placed
                mkdir -p /usr/local/microsoft/powershell/7.3.4

                # Expand PowerShell to the target folder
                tar zxf /tmp/powershell.tar.gz -C /usr/local/microsoft/powershell/7.3.4

                # Set execute permissions
                chmod +x /usr/local/microsoft/powershell/7.3.4/pwsh

                # Create the symbolic link that points to pwsh
                ln -s /usr/local/microsoft/powershell/7.3.4/pwsh /usr/local/bin/pwsh

                # Start PowerShell
                pwsh
            fi
        fi
    fi
else
    echo "This script is only for Linux or macOS"
    echo "See the following for information on installing PowerShell: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3"
fi
