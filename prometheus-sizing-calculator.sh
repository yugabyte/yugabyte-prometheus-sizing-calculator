#!/bin/bash

# This script calculates Prometheus resource estimates by processing each universe individually.
#
# Usage:
#   Provide one or more universes using the -u flag.
#
# Example:
#   bash prometheus-sizing-calculator.sh -u 'Universe-1 Name:No of Tables:No of Nodes' -u 'Universe-2 Name:No of Tables:No of Nodes'
#   bash prometheus-sizing-calculator.sh -u 'Prod:500:3' -u 'Dev:1000:3'

# Function to display messages in bold without prompting for user input
bold_echo() {
  if [ "$1" == "-n" ]; then
    shift
    echo -ne "\033[1m$@\033[0m"
  else
    echo -e "\033[1m$@\033[0m"
  fi
}

# Function for prompting user input with bold text without a newline after the prompt
bold_read() {
  echo -n -e "\033[1m$1\033[0m "
  read $2
}

# About this script:
echo ""
echo "- This script interactively estimates memory, disk, and CPU requirements for your YugabyteDB Anywhere node running Prometheus, YB-Platform, and Postgres services."
echo -n "- For more information, visit: "
bold_echo "https://support.yugabyte.com/hc/en-us/articles/38092646336909-How-to-Estimate-Prometheus-Resource-Requirements-for-YugabyteDB-Anywhere"
bold_echo -n "- GitHub"; echo ": https://github.com/yugabyte/yugabyte-prometheus-sizing"

# --- Help ---
usage() {
  echo ""
  bold_echo "Usage: $0 -u 'Universe-1 Name:No of Tables:No of Nodes' -u 'Universe-2 Name:No of Tables:No of Nodes' ..."
  echo ""
  echo "Each -u flag represents a universe in the format: name:tables:nodes"
  echo ""
  echo "Example:"
  bold_echo "  $0 -u 'Prod:500:3' -u 'Dev:1000:3'"
  exit 1
}

# --- Prerequisite Check ---
if ! command -v bc &> /dev/null; then
    echo "The 'bc' command is required but not found."
    
    # Auto-install prompt
    read -p "Would you like to try and install it automatically? (y/n) " -n 1 -r
    echo # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Attempting to install 'bc'..."
        
        # Check for OS type
        if [[ "$(uname)" == "Linux" ]]; then
            # Check for common Linux package managers
            if command -v apt-get &>/dev/null; then
                sudo apt-get update && sudo apt-get install -y bc
            elif command -v yum &>/dev/null; then
                sudo yum install -y bc
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y bc
            else
                echo "Could not find a supported package manager (apt, yum, dnf). Please install 'bc' manually."
                exit 1
            fi
        elif [[ "$(uname)" == "Darwin" ]]; then
            # Check for Homebrew on macOS
            if ! command -v brew &>/dev/null; then
                echo "Homebrew not found. Please install Homebrew or install 'bc' manually."
                exit 1
            fi
            brew install bc
        else
            echo "Unsupported OS. Please install 'bc' manually."
            exit 1
        fi
        
        # Verify installation after attempting
        if ! command -v bc &> /dev/null; then
            echo "Failed to install 'bc'. Please install it manually."
            exit 1
        else
            echo "'bc' has been installed successfully."
        fi
    else
        echo "Please install 'bc' manually to proceed."
        exit 1
    fi
fi

# --- Initialization ---
declare -a universes
total_metrics=0

# --- Argument Parsing ---
while getopts ":u:" opt; do
  case $opt in
    u)
      universes+=("$OPTARG")
      ;;
    *)
      usage
      ;;
  esac
done

if [ ${#universes[@]} -eq 0 ]; then
  usage
fi

# --- Processing ---
echo ""
echo "Processing Universes..."
for entry in "${universes[@]}"; do
  IFS=':' read -r name tables nodes <<< "$entry"
  if [[ -z "$name" || -z "$tables" || -z "$nodes" ]]; then
    echo "Invalid universe input: $entry"
    usage
  fi

  # Calculate metrics for this specific universe
  universe_metrics=$(( (60 * tables + 9000) * nodes ))

  # Add this universe's metrics to the grand total
  total_metrics=$(( total_metrics + universe_metrics ))

  bold_echo "  - Universe: $name - Tables: $tables, Nodes: $nodes → Metrics: $universe_metrics"
done

# --- Calculation ---
# Determine memory factor based on the final total
if [ "$total_metrics" -gt 1000000 ]; then
  memory_per_metric=10
else
  memory_per_metric=30
fi

# Calculate final resource needs
memory_kb=$(( total_metrics * memory_per_metric ))
memory_gb=$(echo "scale=2; $memory_kb / 1024 / 1024" | bc)

disk_kb=$(( total_metrics * 253 ))
disk_gb=$(echo "scale=2; $disk_kb / 1024 / 1024" | bc)

cpu=$(echo "scale=2; $total_metrics / 1000000" | bc)

# --- Output ---
echo ""
echo -n "Total Metrics: "; bold_echo "$total_metrics"
echo ""
echo "Estimated Requirements:"
echo -n "  Memory: "; bold_echo "$memory_gb GB"
echo -n "  Disk:   "; bold_echo "$disk_gb GB"
echo -n "  CPU:    "; bold_echo "$cpu cores"
