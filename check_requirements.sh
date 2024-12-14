#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

CHECK_MARK="✅"
CROSS_MARK="❌"

failed=false

required_software=("just" "docker" "terraform" "kubectl" "aws" "helm")

for tool in "${required_software[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}${CROSS_MARK} Error: $tool is not installed or not in your PATH${RESET}"
        failed=true
    else
        echo -e "${GREEN}${CHECK_MARK} $tool is installed${RESET}"
    fi
done

env_vars=("GITHUB_USERNAME" "GITHUB_TOKEN")

for env_var in "${env_vars[@]}"; do
    if [ -z "${!env_var}" ]; then
        echo -e "${RED}${CROSS_MARK} Error: $env_var environment variable is not set${RESET}"
        failed=true
    else
        echo -e "${GREEN}${CHECK_MARK} $env_var is set${RESET}"
    fi
done

if [ "$failed" = true ]; then
    exit 1
fi

echo -e "${GREEN}${CHECK_MARK} All checks passed!${RESET}"