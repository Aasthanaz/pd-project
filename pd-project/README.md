# pd-project — RTL to GDSII, in your browser (GitHub Codespaces)

This repo is a ready-to-run RTL-to-GDSII flow for a small 8-bit counter,
using Yosys + OpenROAD + Magic, on the open SkyWater sky130 PDK.
Everything runs inside a GitHub Codespace — no local installs needed.

## 0. Launch it
1. Push this folder to a new GitHub repo (or upload it via the GitHub web UI).
2. On the repo page: **Code (green button) → Codespaces → Create codespace on main**.
3. Wait for the build. `scripts/setup.sh` runs automatically and installs
   Yosys, Magic, KLayout, Netgen, the sky130 PDK, and pulls the OpenROAD
   docker image in the background. This takes several minutes the first time.
4. **Open a new terminal tab** (important — this loads the env vars that
   `setup.sh` added to `~/.bashrc`).

## 1. Run synthesis (Yosys)
```bash
bash scripts/run_synth.sh
```
Check `run/counter.synth.v` — you should see real cell names like
`sky130_fd_sc_hd__dfxtp_1`, not Verilog `always` blocks.

## 2. Run floorplan → placement → CTS → routing → STA (OpenROAD)
```bash
bash scripts/run_openroad.sh
```
Watch the terminal output for:
- `>>> link_design OK` — netlist correctly linked to the PDK
- `>>> Placement done`
- `>>> CTS done`
- `>>> Routing done`
- The final timing report — look at `report_wns` (Worst Negative Slack).
  **This should be 0 or positive.** If it's negative, timing failed —
  see the Troubleshooting section below.

All intermediate `.def` files land in `run/` — one per stage, so you can
inspect how the design evolves.

## 3. View any stage visually
Open the noVNC desktop tab (Codespaces will prompt you to open forwarded
port 6080), then in the Codespace terminal:
```bash
docker run --rm -it -v "$(pwd)":/pd-project -v "$HOME/.volare":/pdk \
  -e PDK_ROOT=/pdk -w /pd-project -e DISPLAY=$DISPLAY openroad/orfs \
  openroad -gui
```
Inside the GUI's Tcl console:
```tcl
read_lef /pdk/sky130A/libs.ref/sky130_fd_sc_hd/tech/sky130_fd_sc_hd.tlef
read_lef /pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_def run/counter.placement.def   ;# swap in any stage's .def file
```

## 4. DRC check + GDSII export (Magic)
```bash
magic -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc \
  -noconsole scripts/drc_gds.tcl
```
Goal: **zero DRC violations**. Output GDS lands at `run/counter.gds` —
this is your tapeout-ready file.

## 5. Look at the finished layout (KLayout)
```bash
klayout run/counter.gds
```
Opens in the noVNC desktop tab. Toggle layers on/off in the Layers panel.

## Repo structure
```
.devcontainer/devcontainer.json   Codespace environment definition
src/counter.v                     The RTL design
scripts/setup.sh                  Auto-installs everything on first boot
scripts/synth.ys                  Yosys synthesis script
scripts/run_synth.sh              Runs synthesis
scripts/openroad_flow.tcl         Floorplan -> PDN -> placement -> CTS -> route -> STA
scripts/run_openroad.sh           Runs the OpenROAD flow inside docker
scripts/drc_gds.tcl               DRC check + GDS export
run/                              All output files land here (gitignored)
```

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| `link_design` fails | Check `run/counter.synth.v` was actually generated — re-run step 1 |
| `report_wns` negative | Clock period (10ns in `openroad_flow.tcl`) too aggressive — try raising it to 20 |
| `detailed_route` leaves unrouted nets | Lower `-density` in `global_placement` (try 0.4) or enlarge `-die_area` |
| Magic `drc check` shows violations | Almost always from routing — `drc why` tells you the exact rule/location |
| noVNC tab won't load | Make sure port 6080 is forwarded (Ports tab in Codespaces) and set to Public/visible |

## Next steps
Once this passes cleanly end to end, try swapping `src/counter.v` for a
slightly bigger design (e.g. a small UART TX or ALU) and re-run the same
three commands — the flow doesn't change, only the RTL does.
