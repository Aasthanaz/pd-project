#!/usr/bin/env bash
# Runs automatically once, the first time the Codespace is created.
set -e

echo ">>> Updating apt and installing core tools..."
sudo apt-get update
sudo apt-get install -y yosys magic klayout netgen git build-essential python3-pip

echo ">>> Installing volare (PDK manager)..."
pip3 install --user volare

echo ">>> Fetching SkyWater sky130 PDK (this takes a few minutes)..."
export PATH="$HOME/.local/bin:$PATH"
volare enable --pdk sky130 "$(volare ls-remote --pdk sky130 | tail -1)"

echo ">>> Persisting environment variables for future terminals..."
{
  echo 'export PATH="$HOME/.local/bin:$PATH"'
  echo 'export PDK_ROOT=~/.volare'
  echo 'export PDK=sky130A'
} >> ~/.bashrc

echo ">>> Pulling OpenROAD docker image (this takes a few minutes, runs in background)..."
( docker pull openroad/orfs > /tmp/orfs_pull.log 2>&1 & )

echo ">>> Setup complete. Open a NEW terminal tab (so the env vars load), then run:"
echo "    bash scripts/run_synth.sh"
