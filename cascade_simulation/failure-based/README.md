# Failure-Based Strategy

## Introduction

The failure-based strategy focuses on upgrading transmission lines that fail during the cascading process. The lines are selected based on their failure order, and once a failure occurs, the strategy can either upgrade the first failing line or all the failing lines in sequence.

In this strategy, users have the option to:
- Choose whether to upgrade only the first failing line or all failing lines.
- Select whether to upgrade the line's capacity to infinity or to its current overloaded capacity.

## Key Function: `runMPCS_failure`

This function simulates the cascade event using the failure-based strategy and upgrades the failing lines based on the specified criteria. Below are the details of the function.

```matlab
runMPCS_failure(dataName, K, demand_ratio, line_cap_ratio, seed, ffl, toInf)
```
## Parameters:
- **dataName**: The name of the Matpower case file (e.g., 'case3375wp'). The provided data can be in `.mat` format or as a function (e.g., `case3375wp` for Matpower case function).
- **K**: Number of cascade realizations (default: 100).
- **demand_ratio**: Scaling factor for power demand (default: 1.2).
- **line_cap_ratio**: Scaling factor for transmission line capacity (default: 1.0).
- **seed**: Seed for random number generation (default: 1).
- **ffl**: Option to upgrade only the first failing line (default: 0, used in frequency-based and failure-based strategies).
- **toInf**: Option to increase line capacities to infinity or to overloaded values (default: 0).

### Example:
```matlab
runMPCS_failure('case3375wp', 100, 1.2, 1.0, 1, 0, 0)
```

## Code Flow

### 1. **Data Preparation**

- The system is initialized by loading the Matpower case and preparing the initial state using the `prepareInitialState.m` function. This includes scaling the load and generation, adjusting capacities, and performing initial power flow calculations.

Before running the cascade simulation, the initial power grid state needs to be prepared:

i. **Loading the Matpower Case Data**:
- The first step is to load a Matpower case file, which contains the system’s power grid data. This includes information about buses, generators, and transmission lines.
- You can provide your own Matpower case file, or use the default ‘case3375wp.m’ file in the ‘data/’ folder.

ii. **Scaling Demand and Generation**:
- The demand (PD, QD) and generation (PG) for each bus and generator are scaled by the `demand_ratio`.
- Transmission line capacities are scaled by the `line_cap_ratio`.

iii. **Generator Modifications**:
- Generators with zero capacity are marked as out-of-service, and any generators whose power output exceeds their maximum capacity are adjusted accordingly.
- Negative load buses are converted to PV buses with newly added generators to balance the negative load.

iv. **Transmission Line Handling**:
- Transmission lines that are out of service (BR_STATUS == 0) are removed from the system.
- Phase shifters and shunt adjustments are handled automatically.

v. **Capacity Overload**:
- If any transmission line exceeds its rated capacity by more than 5%, the line capacity is adjusted to ensure safe operation.

This data preparation step ensures that the simulation begins with a realistic and scalable power grid model.

### 2. **Cascade Simulation**

- The cascade event simulation is handled by the `runCascadeAndUpgrade.m` function. This function simulates the cascading failures and upgrades the capacities of the failed lines. The cascade failures are modeled with various strategies, such as upgrading the first failing lines or increasing the capacities to infinity.

i. **Run Cascade Event**:
- The `runCascadeAndUpgrade` function triggers the cascade simulation. It begins by simulating a cascade event, where failures occur in the grid.
- The function checks if any lines fail, and based on the failure event, it upgrades the line capacities (depending on the `ffl` and `toInf` options).

ii. **Handling the Failed Lines**:
- The function identifies the lines that have failed, and then applies the appropriate upgrade strategy to handle them.
- If `ffl` is set to 1, only the first failed lines are upgraded, otherwise, all failed lines are considered.
- If `toInf` is set to 1, the capacities of the failed lines are increased to infinity, otherwise, the capacity is increased to the overloaded value.

### 3. **Power Flow Calculation**

- The `computePowerFlow.m` function calculates the DC power flow using the B matrix and the power injections, which are updated after each failure. This step ensures the system state reflects the cascading failures.

i. **Updating the B Matrix**:
- The B matrix represents the system’s admittance matrix, which is crucial for calculating power flow. The matrix is updated using the system’s current state (e.g., after line failures).
- This update ensures that the network’s connections and power flows are accurately represented.

ii. **Power Flow Calculation**:
- The DC power flow is then calculated using the updated B matrix and the power injections (including generator outputs and demand).
- This step ensures that the flow of power through the system is recalculated after each failure, reflecting the new state of the grid.

### 4. **Capacity Updates**

- The capacity of transmission lines is updated based on the failure and upgrade strategy, either increasing the capacity to infinity or adjusting based on the overload value.

i. **Updating Line Capacities**:
- Once the power flow is calculated, the capacities of transmission lines are adjusted if necessary. This is particularly important if any lines have become overloaded or failed during the cascade.
- The capacity updates are based on the `toInf` and `ffl` parameters, ensuring that the network can handle the increased power flow after failures.

## Results

The results are saved in the `results/` folder, with filenames based on the input parameters.

### Output Data:
- **cs**: The cascade simulator object containing the state of the system.
- **mpc0**: The initial state of the system.
- **caps**: A matrix of updated line capacities for each realization.

### Example of saving results:

```matlab
save(['results/', fileName, '.mat'], 'cs', 'mpc0', 'caps', '-v7.3');
```

The cases variable stores the overloaded lines and their corresponding power demand values for each realization. This data can be used to analyze the performance of the overload-based strategy and the effect of different upgrades on preventing cascades.

### Example of retrieving the overloaded lines and their power demand:

```matlab
[overloadedLines, overloadPower] = check_overload(cs, alpha);
disp('Overloaded Lines and Power Demand:');
disp(overloadedLines);
disp(overloadPower);
```

## Conclusion

The failure-based strategy simulates cascading failures and applies upgrades to transmission lines based on their failure sequence. This strategy provides a way to explore the effectiveness of upgrading failing lines to maintain network stability and prevent total failure.

For more general ideas about the rest of the code package, refer to the [general README](../README.md).
