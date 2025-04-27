# Cascade simulation code

## Folders
* [`frequency-based`](frequency-based): Frequency-based strategy simulation code
* [`failure-based`](failure-based): Failure-based strategy simulation code
* [`overload-based`](overload-based): Overload-based strategy simulation code

## Usage

### Running the Simulation:

Use the functions `runMPCS_failure`, `runMPCS_frequency`, and `runMPCS_overload` to start the cascade simulations. These functions simulate cascading failures using different strategies: Failure-based, Frequency-based, and Overload-based strategies.

#### Function Syntax:

- `runMPCS_failure(dataName, K, demand_ratio, line_cap_ratio, seed, ffl, toInf)`
- `runMPCS_frequency(dataName, NofInc, K, demand_ratio, line_cap_ratio, threshold, seed, ffl, toInf)`
- `runMPCS_overload(dataName, K, demand_ratio, line_cap_ratio, seed)`

Parameters:
- `dataName`: Name of the Matpower case file (e.g., 'case3375wp'). The provided data can be in a `.mat` format or as a function (e.g., `case3375wp` for Matpower case function).
- `K`: Number of cascade realizations (default: 100).
- `NofInc`: Number of planned upgrade iterations (only for the frequency-based strategy).
- `demand_ratio`: Scaling factor for power demand (default: 1.2).
- `line_cap_ratio`: Scaling factor for transmission line capacity (default: 1.0).
- `threshold`: Vulnerable line failure threshold (only for the frequency-based strategy).
- `seed`: Seed for random number generation (default: 1).
- `ffl`: Option to upgrade only the first failing lines (default: 0, used in frequency-based and failure-based strategies).
- `toInf`: Option to increase line capacities to infinity or to overloaded values (default: 0).

Example:

```matlab
runMPCS_failure('case3375wp', 100, 1.2, 1.0, 1, 0, 0)
runMPCS_frequency('case3375wp', 3, 100, 1.2, 1.0, 1, 1, 0, 0)
runMPCS_overload('case3375wp', 100, 1.2, 1.0, 1)
```

## Demo Script: `runCascadeSimulationDemo.m`

The demo script allows users to choose one of the cascade simulation strategies interactively. The script provides options to run any of the available strategies (Failure-based, Frequency-based, or Overload-based) with customizable parameters.

### How it Works:

#### 1. **Strategy Selection**: The user is prompted to choose which strategy to run:
- 1: Failure-based
- 2: Frequency-based
- 3: Overload-based

#### 2. **Parameter Input**: After choosing a strategy, the user is prompted to input the necessary parameters for the chosen strategy:
- For **Failure-based** and **Frequency-based** strategies: The user is asked for parameters like `ffl`, `toInf`, `NofInc`, `threshold`, etc.
- For **Overload-based**: Only the basic parameters (`dataName`, `K`, `demand_ratio`, etc.) are needed.

#### 3. **Running the Strategy**: Based on the user input, the corresponding function (`runMPCS_failure`, `runMPCS_frequency`, or `runMPCS_overload`) is executed with the provided parameters.

#### How to Use the Demo Script:

1. Run the script `runCascadeSimulationDemo.m` in MATLAB.
2. The script will prompt you to select a strategy (Failure-based, Frequency-based, or Overload-based).
3. Enter the required parameters for the selected strategy.
4. The chosen cascade simulation strategy will run, and results will be saved in the `results/` directory.

## Conclusion

This simulation helps characterize cascading failures in power networks and explores strategies to mitigate the "whack-a-mole" effect. The system allows the testing of different failure and upgrade strategies, providing valuable insights into network stability.

For more detailed information on each strategy, refer to their respective README files:
- [Failure-Based Strategy](failure-based/README.md)
- [Frequency-Based Strategy](frequency-based/README.md)
- [Overload-Based Strategy](overload-based/README.md)