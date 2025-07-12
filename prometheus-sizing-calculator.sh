#!/bin/bash

# Usage help
usage() {
  echo "Usage: $0 -u 'name1:tables1:nodes1' -u 'name2:tables2:nodes2' ..."
  echo ""
  echo "Each -u flag represents a universe in the format:"
  echo "  name:tables:nodes"
  echo ""
  echo "Example:"
  echo "  $0 -u 'Yugabyte-Dev-Cluster:1000:3' -u 'Yugabyte-Dev-Cluster:500:6'"
  exit 1
}

# Check if bc is installed
if ! command -v bc &> /dev/null; then
  echo "This script requires 'bc'. Please install it (e.g., 'sudo apt install bc')."
  exit 1
fi

# Initialize
declare -a universes
total_metrics=0

# Parse flags
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

# Process each universe
for entry in "${universes[@]}"; do
  IFS=':' read -r name tables nodes <<< "$entry"
  if [[ -z "$name" || -z "$tables" || -z "$nodes" ]]; then
    echo "Invalid universe input: $entry"
    usage
  fi

  metrics=$(( (60 * tables + 9000) * nodes ))
  total_metrics=$(( total_metrics + metrics ))

  echo "Universe: $name - Tables: $tables, Nodes: $nodes → Metrics: $metrics"
done

# Memory per metric
if [ "$total_metrics" -gt 1000000 ]; then
  memory_per_metric=10
else
  memory_per_metric=30
fi

# Calculations
memory_kb=$(( total_metrics * memory_per_metric ))
memory_gb=$(echo "scale=2; $memory_kb / 1024 / 1024" | bc)

disk_kb=$(( total_metrics * 253 ))
disk_gb=$(echo "scale=2; $disk_kb / 1024 / 1024" | bc)

cpu=$(echo "scale=2; $total_metrics / 1000000" | bc)

# Output summary
echo ""
echo "Total Metrics: $total_metrics"
echo "Estimated Requirements:"
echo "  Memory: $memory_gb GB"
echo "  Disk:   $disk_gb GB"
echo "  CPU:    $cpu cores"
