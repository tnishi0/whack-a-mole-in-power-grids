# Simulation and Visualization Code for "Characterizing and countering the whack-a-mole effect in network cascades"
__Authors__: Deniz Eroglu, Takashi Nishikawa, and Adilson E. Motter

This repository contains code for running cascade simulations for power-grid networks and exploring strategies to counter the "whack-a-mole" effect. The whack-a-mole effect refers to the phenomenon where mitigating one failure leads to the emergence of new failures, complicating efforts to enhance the overall robustness of the system against cascading failures. The repository also includes code for reproducing the figures related to the power-grid results presented in the paper. 

## Folders
* [`cascade_simulation`](cascade_simulation): Code for running cascade simulations.
* [`figures`](figures): Code for reproducing the figures on power-grid cascades in the manuscript. 
* [`library`](library): Files and packages defining reusable functions.

## Installation

### Prerequisites:
- MATLAB (Recommended version: R2024b or higher).
- (Required only for the extrapolation curves in Extended Data Fig. 10) MATLAB Curve Fitting Toolbox.
- Matpower [only version 6 is tested] (Download from https://matpower.org/download/all-releases/).

### Setup Instructions:
1. Download this repository and place it in a directory on your system. This should take less than a minute on a typical desktop computer.
2. Download Matpower version 6 from the official release page: https://matpower.org/download/all-releases/ and place it inside the folder `library`. This should also take less than a minute on a typical desktop computer.

## Usage
Start Matlab in this folder. Then, execute:
* `cd cascade_simulation` to go into the `cascade_simulation` folder and follow [the instructions there](cascade_simulation) to run sample cascade simulations (including the typical run time information). To run cascade simulations on your power system data, put the data in the Matpower case file format and follow the instructions in the `cascade_simulation` folder.
* `cd figures` to go into the `figures` folder and follow [the instructions there](figures) to run the code to reproduce figures in the manuscript. It takes approximately 5 min to run the demo `generate_figures` with option `a` and generate all the figures on a typical desktop computer.
