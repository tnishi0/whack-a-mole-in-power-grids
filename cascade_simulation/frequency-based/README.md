# Frequency-Based Strategy

## Introduction

The frequency-based strategy focuses on upgrading transmission lines based on their failure frequencies. This approach identifies which lines fail most frequently during multiple cascade simulations and upgrades them to prevent further instability. By analyzing the frequency of failures, the strategy targets the lines most prone to failure, improving network stability.

In this strategy, users have the option to:
- Choose whether to upgrade only the first failing line or all failing lines.
- Select whether to upgrade the line's capacity to infinity or to its current overloaded capacity.
- Specify the number of upgrade iterations (`NofInc`) and the vulnerable line failure threshold.

## Key Function: `runMPCS_frequency`

This function simulates the cascade event using the frequency-based strategy and upgrades the lines based on the frequency of their failures. Below are the details of the function.

```matlab
runMPCS_frequency(dataName, NofInc, K, demand_ratio, line_cap_ratio, threshold, seed, ffl, toInf)
```

## Parameters:
- **dataName**: The name of the Matpower case file (e.g., 'case3375wp'). The provided data can be in `.mat` format or as a function (e.g., `case3375wp` for Matpower case function).
- **NofInc**: Number of planned upgrade iterations (default: 1).
- **K**: Number of cascade realizations (default: 30).
- **demand_ratio**: Scaling factor for power demand (default: 1.2).
- **line_cap_ratio**: Scaling factor for transmission line capacity (default: 1.0).
- **threshold**: Vulnerable line failure threshold (default: 1).
- **seed**: Seed for random number generation (default: 1).
- **ffl**: Option to upgrade only the first failing line (default: 0, used in frequency-based and failure-based strategies).
- **toInf**: Option to increase line capacities to infinity or to overloaded values (default: 0).

### Example:
```matlab
runMPCS_frequency('case3375wp', 3, 100, 1.2, 1.0, 1, 1, 0, 0)
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

- The cascade event simulation is handled by the `runMultipleCascadeEvents.m` function. This function simulates the cascading failures and upgrades the capacities of the failed lines. The cascade failures are modeled with various strategies, such as upgrading the first failing lines or increasing the capacities to infinity.

i. **Running Multiple Cascade Events**:
- The `runMultipleCascadeEvents` function triggers the cascade simulation. It simulates multiple cascade events in the grid, and the system state is updated after each cascade.
- The function checks which lines fail and based on the failure event, it upgrades the line capacities (depending on the `ffl` and `toInf` options).

ii. **Handling the Failed Lines**:
- The function identifies the lines that have failed, and then applies the appropriate upgrade strategy to handle them.
- If `ffl` is set to 1, only the first failed lines are upgraded; otherwise, all failed lines are considered.
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

- The capacity of transmission lines is updated based on the frequency of their failures and the specified upgrade strategy. If the frequency of failure for a line exceeds the threshold, its capacity is increased. The increase can either be to infinity or to the current overload value, depending on the `toInf` parameter.

i. **Updating Line Capacities**:
- Lines that are identified as vulnerable (those that exceed the failure threshold) will have their capacities updated.
- The capacity update can be one of the following:
   - If `toInf` is set to 1, the capacity of the selected lines is increased to infinity.
   - If `toInf` is set to 0, the capacity of the selected lines is increased to their overloaded value (current overload value + a small epsilon).
- This step ensures that vulnerable lines are upgraded to prevent further failure, maintaining network stability during the cascade.

## Results

The results from running the frequency-based strategy are stored in the `results/` folder, with filenames generated based on the input parameters. These results contain data on the cascade simulation and the performance of the upgrade strategy.

### Output Data:
- **csc**: A cell array containing the state of the simulation after each realization. Each element is a copy of the cascade simulator object (`cs`), allowing for detailed analysis of the cascade behavior across realizations.
- **fileName**: The name of the file where the results are saved, based on the simulation parameters.

### Example of saving results:

```matlab
save(['results/', fileName, '.mat'], 'csc', '-v7.3');
```
## Conclusion

The frequency-based strategy addresses the cascading failures by focusing on upgrading lines that are frequently involved in failure events. By upgrading vulnerable lines based on the frequency of their failure, the system aims to reduce the recurrence of failures and prevent the collapse of the network. This strategy allows users to control how many upgrade iterations should take place, and which lines should be prioritized for capacity upgrades.

For more general ideas about the rest of the code package, refer to the [general README](../README.md).
