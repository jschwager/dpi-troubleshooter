#!/bin/bash
# Name: DreamPi Troubleshooter
# Description: A script to troubleshoot DreamPi setup issues
# Author: Jared Schwager

VERSION="0.9.1"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Function to check network connectivity
check_network() {
    echo -e "\n${BOLD}=== Network Connectivity Check ===${NORMAL}"
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}●${NC} Network is reachable"
    else
        echo -e "${RED}●${NC} Network is not reachable, please check your connection."
        read -p "Would you like to configure WiFi? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo wificonfig
        fi
    fi
}

# Function to check if DreamPi service exists
check_service() {
    echo -e "\n${BOLD}=== DreamPi Service Check ===${NORMAL}"
    if systemctl list-unit-files | grep -q dreampi; then
        echo -e "${GREEN}●${NC} dreampi service found"
        return 0
    else
        echo -e "${RED}●${NC} dreampi service not found"
        return 1
    fi
}

# Function to get DreamPi service status
get_status() {
    echo -e "\n${BOLD}=== DreamPi Service Status ===${NORMAL}"
    systemctl status dreampi --no-pager --lines=0
}

# Function to analyze DreamPi logs
analyze_logs() {
    echo -e "\n${BOLD}=== Recent DreamPi Logs ==="
    journalctl -u dreampi -n 50 --no-pager
}

# Function to check for common errors
check_errors() {
    echo -e "\n${BOLD}=== Checking for Common Errors ===${NORMAL}"
    if journalctl -u dreampi | grep -qi "error\|failed\|denied"; then
        echo -e "${RED}●${NC} Errors found in logs:"
        journalctl -u dreampi | grep -i "error\|failed\|denied" | tail -10
    else
        echo -e "${GREEN}●${NC} No common errors detected"
    fi
}

# Function to check for modem errors
check_modem_errors() {
    echo -e "\n${BOLD}=== Checking for Modem Errors ===${NORMAL}"
    if journalctl -u dreampi | grep -qi "could not open port /dev"; then
        echo -e "${RED}●${NC} Modem could not be detected."
        journalctl -u dreampi | grep -i "could not open port /dev" | tail -10
    else
        echo -e "${GREEN}●${NC} No modem related errors detected"
    fi
}

# Function to check for dialing issues
check_dialing_issues() {
    echo -e "\n${BOLD}=== Checking for Dialing Issues ===${NORMAL}"
    if journalctl -u dreampi | grep -qi "Heard: [0-9][0-9][0-9][0-9][0-9][0-9][0-9]$"; then
        echo -e "${GREEN}●${NC} Detected dialing a 7-digit number. This indicates a correct dialing sequence."
        journalctl -u dreampi | grep -i "Heard: [0-9][0-9][0-9][0-9][0-9][0-9][0-9]$" | tail -4
    elif journalctl -u dreampi | grep -qi "Heard:"; then
        echo -e "${RED}●${NC} A dialing attempt was detected, however it was not a 7-digit number."
        journalctl -u dreampi | grep -i "Heard:" | tail -4
    else
        echo -e "${RED}●${NC} A dialing attempt was not detected. Please try dialong again before running the troubleshooter."
    fi
}

# Main execution
echo "▗▄▄▄   ▄▄▄ ▗▞▀▚▖▗▞▀▜▌▄▄▄▄  ▗▄▄▖ ▄ "
echo "▐▌  █ █    ▐▛▀▀▘▝▚▄▟▌█ █ █ ▐▌ ▐▌▄ "
echo "▐▌  █ █    ▝▚▄▄▖     █   █ ▐▛▀▘ █ "
echo -e "▐▙▄▄▀                      ▐▌   █ ${BOLD}troubleshooter"
echo -e "${NORMAL}v${VERSION} by Jared Schwager" 

check_network
check_service
get_status
check_errors
check_modem_errors
check_dialing_issues

echo -e "\nTroubleshooting complete.\n"
read -p "Would you like to see recent logs? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    analyze_logs
fi