#!/bin/bash
# setup-run-dir.sh
# Usage: setup-run-dir.sh <task-slug>
# Creates ~/Claude-Stuff/spawn-team-runs/{run-id}/ with standard subdirs.
# Prints the absolute run-dir path on stdout.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <task-slug>" >&2
  echo "Example: $0 cache-strategy" >&2
  exit 1
fi

slug="$1"

# Validate slug: kebab-case, 1-30 chars, no slashes
if ! echo "$slug" | grep -qE '^[a-z0-9-]{1,30}$'; then
  echo "Error: slug must be kebab-case (lowercase, digits, hyphens), 1-30 chars" >&2
  echo "Got: $slug" >&2
  exit 1
fi

date_part=$(date +%Y-%m-%d)
time_part=$(date +%H%M%S)
run_id="${date_part}-${slug}-${time_part}"

base_dir="${HOME}/Claude-Stuff/spawn-team-runs"
run_dir="${base_dir}/${run_id}"

# Create the run-dir and standard role subdirectories.
mkdir -p \
  "${run_dir}/researchers" \
  "${run_dir}/finders" \
  "${run_dir}/counters" \
  "${run_dir}/arguers" \
  "${run_dir}/contrarians" \
  "${run_dir}/aggregator"

# Print absolute path on stdout. Lead captures this with $(...).
echo "${run_dir}"
