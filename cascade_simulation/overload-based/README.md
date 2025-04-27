# Overload-Based Strategy

## Introduction

The overload-based strategy focuses on upgrading transmission lines that are at risk of overload due to initial line failures. Instead of waiting for lines to fail during a cascade, this strategy calculates the minimum capacity increase required for each overloaded line to prevent failure and stabilize the system.

In this strategy, users have the option to:
- Prevent cascading failures by upgrading overloaded lines.
- Choose whether to upgrade the capacity of overloaded lines to infinity or to their current overload value.



## Key Function: `runMPCS_overload`

This function simulates the cascade event using the overload-based strategy and upgrades the capacities of overloaded lines based on the calculated overload amounts. Below are the details of the function.

```matlab
runMPCS_overload(dataName, K, demand_ratio, line_cap_ratio, seed)
```

## Parameters:
- **dataName**: The name of the Matpower case file (e.g., 'case3375wp'). The provided data can be in `.mat` format or as a function (e.g., `case3375wp` for Matpower case function).
- **K**: Number of cascade realizations (default: 100).
- **demand_ratio**: Scaling factor for power demand (default: 1.2).
- **line_cap_ratio**: Scaling factor for transmission line capacity (default: 1.0).
- **seed**: Seed for random number generation (default: 1).

### Example:
```matlab
runMPCS_overload('case3375wp', 100, 1.2, 1.0, 1)
```

## Code Flow

### 1. Data Preparation

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

### 2. Cascade Simulation

- The cascade event simulation is handled by the `computeOverload.m` function. This function simulates the cascading failures and upgrades the capacities of the overloaded lines.

i. **Run Cascade Event**:
- The `computeOverload.m` function simulates the cascade event, which starts by identifying overloaded lines based on the current power flow after each failure.

ii. **Handling the Overloaded Lines**:
- The overloaded lines are identified, and their capacities are increased to prevent further failure.
- The capacity of each overloaded line is upgraded either by increasing it to infinity or to the overloaded capacity, depending on the `toInf` setting.

### 3. Power Flow Calculation

- The `computePowerFlow.m` function calculates the DC power flow using the B matrix and the power injections, which are updated after each failure. This ensures that the system state reflects the cascading failures.

i. **Updating the B Matrix**:
- The B matrix represents the system’s admittance matrix, which is crucial for calculating power flow. The matrix is updated using the system’s current state (e.g., after line failures).

ii. **Power Flow Calculation**:
- The DC power flow is then calculated using the updated B matrix and the power injections (including generator outputs and demand). This ensures that the flow of power through the system is recalculated after each failure, reflecting the new state of the grid.

### 4. Capacity Updates

- The capacity of transmission lines is updated based on the overload strategy, either increasing the capacity to infinity or adjusting based on the overload value.

i. **Updating Line Capacities**:
- Once the power flow is calculated, the capacities of transmission lines are adjusted if necessary. This is particularly important if any lines have become overloaded during the cascade.
- The capacity updates are based on the `toInf` parameter, ensuring that the network can handle the increased power flow after failures.

## Results

The results are saved in the `results/` folder, with filenames based on the input parameters.

### Output Data:
- **cases**: A matrix of overloaded lines and their corresponding overload power demands for each realization.

### Example of saving results:

```matlab
save(['results/', fileName, '.mat'], 'cases', '-v7.3');
```

## Conclusion

The overload-based strategy focuses on preventing cascading failures by upgrading the transmission lines that are identified as overloaded during the simulation. By calculating the necessary capacity increases for each line based on the initial perturbations, this strategy aims to minimize the risk of further failures without simulating full cascade events.

This strategy ensures that the system remains stable by addressing the most critical lines and upgrading their capacities. It differs from the frequency- and failure-based strategies by focusing on preventing line overloads rather than responding to failures. This approach is computationally efficient, as it only requires analyzing the overloads caused by initial perturbations rather than running full cascade simulations.

For more general ideas about the rest of the code package, refer to the [general README](../README.md).