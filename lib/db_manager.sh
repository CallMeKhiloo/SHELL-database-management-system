#!/usr/bin/env bash

script_dir="${PROJECT_ROOT}/lib/database"

for file in "${script_dir}"/*.sh; do
  [[ -f "$file" ]] && source "$file"
done
