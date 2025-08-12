#!/bin/bash

PROM_URL="https://10.231.0.20:9090"
CURL_OPTS="-k"  # Skip TLS verification, remove if using valid cert

labels=$(curl $CURL_OPTS -s "$PROM_URL/api/v1/labels" | jq -r '.data[]')

for label in $labels; do
  # Skip labels with unsafe characters
  if [[ "$label" =~ [^a-zA-Z0-9_] ]]; then
    continue
  fi

  echo "🔍 Label: $label"

  # Query Prometheus
  query="count by (job) ({$label!=\"\"})"
  response=$(curl $CURL_OPTS -sG "$PROM_URL/api/v1/query" --data-urlencode "query=$query")

  # Parse and sort results
  total=0
  echo "$response" \
    | jq -r '.data.result[] | "\(.metric.job) \(.value[1])"' \
    | sort -k2 -nr \
    | while read -r job count; do
        printf "  %-30s %10s\n" "$job" "$count"
        total=$((total + count))
      done

  echo "  --------------------------------------------"
  echo "  TOTAL for label '$label': $total"
  echo
done
