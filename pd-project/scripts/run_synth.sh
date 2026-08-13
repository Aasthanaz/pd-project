#!/usr/bin/env bash
# Run logic synthesis on counter.v
set -e
mkdir -p run
yosys -s scripts/synth.ys
echo ""
echo ">>> Done. Check run/counter.synth.v — you should see sky130_fd_sc_hd__ cells,"
echo "    not 'always' blocks. That confirms synthesis + tech mapping worked."
