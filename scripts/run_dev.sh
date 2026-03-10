#!/usr/bin/env bash

set -e

if [ -z "$FINNHUB_API_KEY" ]; then
  echo "ERROR: FINNHUB_API_KEY no está definida."
  echo "Ejemplo:"
  echo 'export FINNHUB_API_KEY="tu_api_key"'
  exit 1
fi

if [ -z "$TWELVE_DATA_API_KEY" ]; then
  echo "ERROR: TWELVE_DATA_API_KEY no está definida."
  echo "Ejemplo:"
  echo 'export TWELVE_DATA_API_KEY="tu_api_key"'
  exit 1
fi

fvm flutter run -d linux \
  --dart-define=FINNHUB_API_KEY="$FINNHUB_API_KEY" \
  --dart-define=TWELVE_DATA_API_KEY="$TWELVE_DATA_API_KEY"
