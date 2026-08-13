#!/usr/bin/env bash
# Runs the OpenROAD flow (floorplan -> routing -> STA) inside the openroad/orfs container.
set -e

docker run --rm \
  -v "$(pwd)":/pd-project \
  -v "$HOME/.volare":/pdk \
  -w /pd-project \
  -e PDK_ROOT=/pdk \
  openroad/orfs \
  openroad -exit scripts/openroad_flow.tcl
