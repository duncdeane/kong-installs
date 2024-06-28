#!/bin/bash

# Define colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if a parameter is passed
if [ -z "$1" ]; then
  echo -e "Please specify the OSS mode you would like to stop ${GREEN}db-less${NC} or ${GREEN}database${NC}"
  exit 1
fi

# Execute the appropriate command based on the parameter
if [ "$1" == "db-less" ]; then
  docker-compose down
elif [ "$1" == "database" ]; then
  KONG_DATABASE=postgres docker compose --profile database down
else
  echo -e "Invalid mode specified. Please specify ${GREEN}db-less${NC} or ${GREEN}database${NC}"
  exit 1
fi
