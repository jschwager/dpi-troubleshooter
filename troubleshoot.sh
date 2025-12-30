#!/bin/bash
# Name: DreamPi Troubleshooter
# Description: A script to troubleshoot DreamPi setup issues
# Author: Jared Schwager

version="1.0"

# Color codes
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m' # No Color
bold=$(tput bold)
normal=$(tput sgr0)

# Get DreamPi version from dreampi.py
dreampi_version_string=$(grep "dreampi.py_version" ~/dreampi/dreampi.py | grep -oE "[0-9]+$")

# Array of DreamPi date strings to version numbers
declare -A dreampi_versions=(
    ["202512152004"]="2.0"
    ["202402202004"]="1.9"
    ["202305142148"]="1.8"
)

# Function to get DreamPi version
get_dreampi_version() {
   echo -e "\n${bold}=== DreamPi Version Check ===${normal}"
    if [[ -n "${dreampi_versions[$dreampi_version_string]}" ]]; then
        echo -e "${green}●${nc} Detected DreamPi version: ${dreampi_versions[$dreampi_version_string]}"
    else
        echo -e "${red}●${nc} Unknown version"
    fi
}

# Function to check network connectivity
check_network() {
    echo -e "\n${bold}=== Network Connectivity Check ===${normal}"
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${green}●${nc} Network is reachable"
    else
        echo -e "${red}●${nc} Network is not reachable, please check your connection."
        read -p "Would you like to configure WiFi? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo wificonfig
        fi
    fi
}

# Function to check for IP conflict (DreamPi is using .98 address)
check_ip_conflict() {   
    echo -e "\n${bold}=== IP Conflict Check ===${normal}"
    if ip addr show | grep -qE "[0-9]+.[0-9]+.[0-9]+.98" | grep -v "/32"; then
        echo -e "${red}●${nc} IP conflict detected: DreamPi is using the .98 address."
        echo "Please ensure no device on your network is using this IP."
        ip addr show | grep -E "[0-9]+.[0-9]+.[0-9]+.98" | grep -v "/32";
    else
        echo -e "${green}●${nc} No IP conflict detected."
    fi
}

# Function to check if DreamPi service exists
check_service() {
    echo -e "\n${bold}=== DreamPi Service Check ===${normal}"
    if systemctl list-unit-files | grep -q dreampi; then
        echo -e "${green}●${nc} dreampi service found"
        return 0
    else
        echo -e "${red}●${nc} dreampi service not found"
        return 1
    fi
}

# Function to check VPN tunnel status
check_vpn_tunnel() {
    echo -e "\n${bold}=== VPN Tunnel Check ===${normal}"
    gateway_ip=$(ip route | grep "tun0" | grep -oE "[0-9]+.[0-9]+.[0-9]+.1" | head -n 1)
    if ip addr show | grep -q "tun0" && ping -I tun0 -c 1 $gateway_ip &> /dev/null; then
        echo -e "${green}●${nc} VPN tunnel is active, connected to gateway $gateway_ip"
    else
        echo -e "${red}●${nc} VPN tunnel is not active"
    fi
}

# Function to get DreamPi service status
get_status() {
    echo -e "\n${bold}=== DreamPi Service Status ===${normal}"
    systemctl status dreampi --no-pager --lines=0
}

# Function to analyze DreamPi logs
analyze_logs() {
    echo -e "\n${bold}=== Recent DreamPi Logs ==="
    journalctl -u dreampi -n 50 --no-pager
}

# Function to check for modem errors
check_modem_errors() {
    echo -e "\n${bold}=== Checking for Modem Errors ===${normal}"
    if journalctl -u dreampi | grep -qi "could not open port /dev"; then
        echo -e "${red}●${nc} Modem could not be detected."
        journalctl -u dreampi | grep -i "could not open port /dev" | tail -10
    else
        echo -e "${green}●${nc} No modem related errors detected"
    fi
}

# Function to check for dialing issues
check_dialing_issues() {
    echo -e "\n${bold}=== Checking for Dialing Issues ===${normal}"
    if journalctl -u dreampi | grep -qi "Heard: [0-9][0-9][0-9][0-9][0-9][0-9][0-9]$"; then
        echo -e "${green}●${nc} Detected dialing a 7-digit number. This indicates a correct dialing sequence."
        journalctl -u dreampi | grep -i "Heard: [0-9][0-9][0-9][0-9][0-9][0-9][0-9]$" | tail -4
    elif journalctl -u dreampi | grep -qi "Heard:"; then
        echo -e "${red}●${nc} A dialing attempt was detected, however it was not a 7-digit number."
        journalctl -u dreampi | grep -i "Heard:" | tail -4
    else
        echo -e "${red}●${nc} A dialing attempt was not detected. Please try dialing again before running the troubleshooter."
    fi
}

# Main execution
echo "▗▄▄▄   ▄▄▄ ▗▞▀▚▖▗▞▀▜▌▄▄▄▄  ▗▄▄▖ ▄ "
echo "▐▌  █ █    ▐▛▀▀▘▝▚▄▟▌█ █ █ ▐▌ ▐▌▄ "
echo "▐▌  █ █    ▝▚▄▄▖     █   █ ▐▛▀▘ █ "
echo -e "▐▙▄▄▀                      ▐▌   █ ${bold}troubleshooter"
echo -e "${normal}v${version} by Jared Schwager" 

get_dreampi_version
check_network
check_ip_conflict
check_vpn_tunnel
check_service
get_status
check_modem_errors
check_dialing_issues

echo -e "\nTroubleshooting complete.\n"
read -p "Would you like to see recent logs? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    analyze_logs
fi