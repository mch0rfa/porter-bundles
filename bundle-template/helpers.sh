#!/usr/bin/env bash
set -euo pipefail

greet() {
  local name=$1
  echo "hell ${name}"
}

# Call the requested function and pass the arguments as-is
"$@"
