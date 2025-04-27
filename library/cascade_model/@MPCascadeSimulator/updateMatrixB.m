function updateMatrixB(obj)
% Updates the B matrix and the Pbus vector with the current data in
% obj.rmpc.

% Column indices for Matpower case data
GS = 5; % GS refers to the real power generation scaling factor for buses.

% Build the B matrix and phase shift injections using Matpower's makeBdc
% This computes the B matrix (B), Bf (from end of the branch), and phase 
% shift injections (Pbusinj, Pfinj)
[obj.B, obj.Bf, obj.Pbusinj, obj.Pfinj] = makeBdc( ...
    obj.rmpc.baseMVA, obj.rmpc.bus, obj.rmpc.branch);

% Compute complex bus power injections (generation - load), adjusted for
% phase shifters and real shunts.
% This calculates the net power injection at each bus, accounting for
% generator outputs and load demands, adjusted for phase shift and real 
% shunts.
obj.Pbus = real(makeSbus(obj.rmpc.baseMVA, obj.rmpc.bus, obj.rmpc.gen)) ...
    - obj.Pbusinj - obj.rmpc.bus(:, GS) / obj.rmpc.baseMVA;
