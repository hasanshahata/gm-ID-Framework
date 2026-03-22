# gm/ID Characterization & Design Framework

This repository provides a complete, automated framework for characterizing the **65nm CMOS** technology using the $g_m/I_D$ methodology. It acts as a bridge between Cadence Spectre and MATLAB, generating Lookup Tables (LUTs) and providing an interactive GUI for rapid analog IC sizing.

Based on Prof. Boris Murmann's $g_m/I_D$ starter kit, this fork has been heavily modified and customized to resolve 65nm specific hierarchy and node parameter issues.

## 🚀 Key Features
* **Custom 65nm Configuration:** Fully working `techsweep` config handling instance-level parameters and unit requirements.
* **PMOS Sign Correction:** Built-in absolute value formatting for PMOS data to prevent extrapolation errors.
* **Interactive Design GUI (`gm_id_Designer.m`):** A powerful MATLAB tool featuring Cadence-like shortcuts:
  * `v` / `h`: Draggable vertical/horizontal cursors with real-time value intersection tracking.
  * `t`: Dynamic toggle between NMOS and PMOS workspaces.
  * `f`: Automated Figure of Merit (FoM) plotting for finding speed/power sweet spots.
  * `s` / `d`: Synthesis tools for auto-sizing transistors (calculating $W$, $L$, $I_D$, $C_{gg}$) directly from target specs.
  * `e`: Export feature to save sizing reports to a design log text file.
  * `p`: Custom plot generator for any variable (e.g., $C_{gg}/W$, $V_{th}$).
  * `i`: Transistor Profiler: Full DC/AC parameter card.

## 🛠️ How to Use
1. Clone this repository to your Linux environment with Cadence Virtuoso and MATLAB installed.
2. Ensure you have the compiled `cds_srr` MEX files in your MATLAB path to read `.raw` files.
3. Update the model path in `techsweep_confi.m` to point to your local model file `toplevel.scs`.
4. Run `techsweep_spectre.m` to generate the `.mat` databases (or use the pre-generated `tech_nch.mat` / `tech_pch.mat` included).
5. Open `gm_id_Designer.m` to launch the interactive design space.

## 📄 Documentation
For a detailed step-by-step guide on how the configurations were set up and how to use the GUI shortcuts, please refer to the included LaTeX PDF manual.
