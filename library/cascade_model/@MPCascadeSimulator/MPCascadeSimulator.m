classdef MPCascadeSimulator < handle & matlab.mixin.Copyable
    %The `MPCascadeSimulator` class is designed to simulate cascading failures
    % in power grids. 
    %
    % Object class for simulating cascading failures in power grids using
    % Matpower's case data format and relevant power system simulation techniques. 
    % This class provides an efficient and flexible framework for modeling and 
    % analyzing cascading failures in electrical transmission networks, including 
    % the ability to scale system parameters and implement various failure handling strategies.
    
    
    % Public Properties
    properties (Access = public)
        
        % Matpower case file name.
        % The default case file to load (e.g., 'case3375wp'). 
        % This is used as the base data for the simulation.
        MPCaseFileName = 'case3375wp'; 
        
        % Handle to class method implementing a triggering strategy.
        % This will define the method used for triggering cascading failures 
        % in the simulation. For example, it could be a random line failure strategy.
        TriggeringStrategy = [];
        
        % Handle to class method implementing a capacity increasing strategy.
        % This will define the method used for increasing the capacities of failed 
        % lines during cascading events. This is currently not used in the failure-based strategy.
        % CapIncreasingStrategy = [];
        
        % Number of triggers (failures) before the cascade is considered complete.
        % This is used to limit how many lines can fail before stopping the simulation.
        ntrig = 3; 
        
        % Number of simulations completed.
        % Keeps track of how many simulations have been performed. Used for statistics and progress tracking.
        NumSims = 0;
        
        % Power demand scaling factor.
        % The multiplier applied to the base demand values in the system (e.g., 1.2 means 20% increase).
        DemandRatio = 1;
        
        % Transmission line capacity scaling factor.
        % This is the multiplier for the transmission line capacities (e.g., 1.0 means no scaling, 1.5 means 50% more capacity).
        LineCapRatio = 1;
        
        % Number of transmission lines (branches).
        % This is automatically set when the system is initialized.
        nl = [];
        
        % Number of generators.
        % This is automatically set when the system is initialized.
        ng = []; 
                  
        % Simulator status.
        % Keeps track of the current status of the simulator (e.g., running, stopped).
        % This is set to one of the enumeration properties of the class (MPCasSimStatus).
        Status = [];
        
        % Display option for progress.
        % If set to 1, will show progress information. Otherwise, no display.
        dispon = 0;
        
    end
    
    % Constant Properties
    properties (Constant, Access = public)
        
        % Probability threshold for a line to be vulnerable.
        % This threshold determines which lines are considered vulnerable for failure in the system.
        VulnerabilityThreshold = 0.0005;
        
    end
    
    % Private Properties
    properties (Access = private)
        
        % Initial state just before cascades are triggered.
        % Holds the Matpower case data (in Matpower's internal indexing format) at the start of the simulation.
        rmpc0 = []; 
        
        % Current state of the system.
        % Holds the current Matpower case data (in Matpower's internal indexing format) during the simulation.
        rmpc = []; 
        
        % Transmission line temperatures.
        % Used to track the state of line temperatures during the simulation.
        T = []; 
        
        % Line status vector.
        % Tracks the status (on/off) of each line during the simulation.
        Outlines = []; 
        
        % Sequence of failures.
        % Keeps track of the order in which lines fail during the cascade simulation.
        Proc = []; 
        
        % Times between failures.
        % Stores the time between each failure during the simulation.
        Proc_time = []; 
        
        % Time step for the simulation.
        % Used to manage the simulation time in each iteration.
        t = []; 
        
        % Matrix indicating the history of triggers and primary failures.
        % A column corresponds to a simulation, and a row corresponds to a specific line's failure status.
        HistoryFailureSeq = [];
        
        % Necessary capacity increase to prevent failure (max overloaded capacity).
        % Keeps track of how much capacity needs to be added to prevent failure on overloaded lines.
        capOvl = [];
        
        % Overloaded lines
        % Stores the indices of the lines that are overloaded based on the power flow calculations.
        ovl = []
        
        % Overload power demand values
        % Tracks the overload values for each overloaded line, which is the difference between the
        % actual power flow and the threshold (capacity) for the line.
        oPd = [] 

        % Secondary failures.
        % Tracks the secondary failures that happen due to the initial cascade, after the first failures.
        SecFail = [];
        
        % History of secondary failures.
        % Keeps track of all secondary failures that occurred during the simulation.
        HistorySecFailures = [];
        
        % Vector of elapsed CPU run time for simulations.
        % Stores the CPU time taken for each simulation.
        CPUTime = [];
        
        % Vector of indices indicating which connected component the buses belong to.
        % Helps manage and identify which parts of the network are connected during a simulation.
        CompIndex = [];
        
        % Vector of structs to store information on the connected components.
        % Each struct represents a component of the network, including bus information and generator status.
        Component = [];
        
        % The B matrix and associated vectors for DC power flow.
        % These are necessary for power flow calculations and connected component analysis.
        B = [];
        Bf = [];
        Pbus = [];
        Pbusinj = [];
        Pfinj = [];
        
    end
    
    methods (Access = public)
        
        % Constructor: Initialize the simulation with grid data and parameters
        % dataset: name of a Matpower case or a mpc case structure
        % DemandRatio: scaling factor for power demand
        % LineCapRatio: scaling factor for transmission line capacity
        function obj = MPCascadeSimulator(dataset, DemandRatio, LineCapRatio) % CapIncStr,
            % Set the default triggering strategy.
            obj.TriggeringStrategy = @obj.chooseRandomLineUniform;

            if exist('LineCapRatio', 'var')
                obj.LineCapRatio = LineCapRatio; 
            end

            if exist('DemandRatio', 'var')
                obj.DemandRatio = DemandRatio;
            end
            
            % Prepare the initial state of the system as obj.rmpc.
            if nargin == 0
                dataset = obj.MPCaseFileName;  % Use default Matpower case if not provided
            end
            prepareInitialState(obj, dataset)
            
            % Save the prepared initial state.
            obj.rmpc0 = obj.rmpc;
            if obj.dispon
                disp('Matpower case data for the initial state:')
                disp(obj.rmpc0)
            end
            
            obj.capOvl = zeros(size(obj.rmpc0.branch,1),1);
            
            % Record the number of generators and transmission lines.
            obj.ng = size(obj.rmpc.gen,1);
            obj.nl = length(obj.rmpc.branch);

            % Pre-allocate memory for this variable.
            obj.HistoryFailureSeq = spalloc(1, obj.nl, floor(0.1*obj.nl));
            obj.HistorySecFailures = spalloc(1, obj.nl, floor(0.1*obj.nl));
            
        end
        
        function runCascadeEvent(obj, InitFailures)
            % Simulate a cascading failure event and track primary and secondary failures.
            %
            % Parameters:
            %   InitFailures: Initial failures to be considered. If not provided, defaults to none.
            
            % Start timing the simulation
            tstart = tic;
            
            % Initialize the system before running the cascade
            initialize(obj);
            
            % Trigger the failure events (using provided initial failures if any)
            if nargin < 2
                trigger(obj);  % Trigger cascade with default behavior
            else
                trigger(obj, InitFailures);  % Trigger cascade with provided initial failures
            end
            
            % Continue running steps of the cascade simulation until it stops
            while obj.Status ~= MPCasSimStatus.Stopped
                step(obj);  % Run one step of the cascade
            end
            
            % Track primary and secondary failures
            nprim = nnz(obj.Proc) - obj.ntrig;  % Count the number of primary failures
            if nprim > 0  % If there are primary failures, there might be secondary failures
                % Find lines with zero power injection (suspected failures)
                aa = find(obj.rmpc.branch(:,14) == 0);
                bb = full(obj.Proc(obj.Proc ~= 0));  % Get triggered or primary failures
                nsec = length(aa) - length(bb);  % Calculate the number of secondary failures
                obj.SecFail(1:nsec) = setdiff(aa, bb);  % Identify secondary failures
            end
            
            % Save the simulation results
            obj.NumSims = obj.NumSims + 1;
            obj.CPUTime(obj.NumSims) = toc(tstart);  % Store the CPU time for this simulation
            obj.HistoryFailureSeq(obj.NumSims, :) = obj.Proc;  % Save the failure sequence
            obj.HistorySecFailures(obj.NumSims, :) = obj.SecFail;  % Save the secondary failures
        end

        % Overload-based strategy computation
        function [l, m] = computeOverload(obj)
            % Initialize the system
            obj.initialize(); % Reset the system to its initial state
            
            % Trigger cascade event
            obj.trigger();  % Run the trigger for the cascade
            
            % Perform the next step of the cascade
            obj.step();    % Step 1 of cascade simulation (as per your current setup)
            
            % Retrieve overload data
            l = obj.ovl; % Get overload line ID
            m = obj.oPd; % Get overload power demand
        end

        % Get the set of triggered failures
        function l = getTriggers(obj)
            l = full(obj.Proc(1 : obj.ntrig));  % Returns the triggered failures
        end

        % Get the history of triggered failures for all simulations
        function l = getHistoryTriggers(obj)
            l = full(obj.HistoryFailureSeq(1 : obj.NumSims, 1 : obj.ntrig));  % All triggered failures
        end

        % Get the primary failures (after the initial trigger)
        function l = getPrimaryFailures(obj)
            l = obj.Proc(obj.ntrig + 1 : end);  % Primary failures after the initial trigger
            l = full(l(l ~= 0));  % Remove zeros (non-failures)
        end
        
        % Get the history of first failing lines across all simulations
        function l=getFirstFails(obj)
            l = nonzeros(obj.HistoryFailureSeq(1 : obj.NumSims,obj.ntrig+1));  % History of first failing lines
        end

        % Calculate the probability of primary failures occurring
        function p = ProbPrimFail(obj)
            NumPrimFail = zeros(1, obj.nl);
            l = nonzeros(obj.HistoryFailureSeq(:,obj.ntrig+1:end));
            for i = 1 : length(l)
                NumPrimFail(l(i)) = NumPrimFail(l(i)) + 1;
            end
            p = NumPrimFail / obj.NumSims;  % Probability of primary failures
        end

        % Calculate the probability of first failures occurring
        function p = ProbFirstFail(obj)
            NumFirstFail = zeros(1, obj.nl);
            l = nonzeros(obj.HistoryFailureSeq(:,obj.ntrig+1));
            for i = 1 : length(l)
                NumFirstFail(l(i)) = NumFirstFail(l(i)) + 1;
            end
            p = NumFirstFail / obj.NumSims;  % Probability of first failures
        end

        % Calculate the probability of latter failures occurring
        function p = ProbLatterFail(obj)
            NumLatterFail = zeros(1, obj.nl);
            l = nonzeros(obj.HistoryFailureSeq(:,obj.ntrig+2:end));
            for i = 1 : length(l)
                NumLatterFail(l(i)) = NumLatterFail(l(i)) + 1;
            end
            p = NumLatterFail / obj.NumSims;  % Probability of latter failures
        end

        % Get the initial Matpower data structure (pre-cascade state)
        function mpc = getMPC0(obj)
            mpc = int2ext(obj.rmpc0);  % Return the initial state of the Matpower case
        end

        % Get the current Matpower data structure (post-cascade state)
        function mpc = getMPC(obj)
            mpc = int2ext(obj.rmpc);  % Return the current state of the Matpower case
        end

        % Get the state of the simulation (line temperatures, outline status, etc.)
        function s = getState(obj)
            s.T = obj.T;
            s.Outlines = obj.Outlines;
            s.Proc = obj.Proc;
            s.Proc_time = obj.Proc_time;  % State information for the simulation
        end

        % Get the total load of the system
        function tl = getTotalLoad(obj)
            if isempty(obj.rmpc)
                tl = [];
                return
            end
            ix = obj.rmpc.bus(:,3) > 0;  % Select buses with positive load
            tl = sum(obj.rmpc.bus(ix,3));  % Total load in the system
        end

        % Get the total generation of the system
        function tg = getTotalGeneration(obj)
            if isempty(obj.rmpc)
                tg = [];
                return
            end
            tg = sum(obj.rmpc.gen(obj.rmpc.gen(:,2) > 0, 2));  % Total generation in the system
        end

        % Get the total CPU time used by the simulation
        function t = getCPUTime(obj)
            t = obj.CPUTime;  % Total CPU time for simulations
        end

        % Get the history of failures during the simulation
        function seq = getHistoryFailureSeq(obj)
            seq = obj.HistoryFailureSeq;  % History of failure sequences
            % Get rid of trailing zeros
            i = find(sum(seq > 0, 1) == 0, 1, 'first') - 1;
            seq = seq(:,1:i);
        end

        % Get the history of secondary failures during the simulation
        function seq = getHistorySecFailureSeq(obj)
            seq = obj.HistorySecFailures;  % History of secondary failures
            % Get rid of trailing zeros
            i = find(sum(seq > 0, 1) == 0, 1, 'first') - 1;
            seq = seq(:,1:i);
        end

        % Get the capacity overload data
        function co = getCapacityOverload(obj)
            co = obj.capOvl;  % Capacity overload data
        end

        % Get the cascade sizes (number of failures in each simulation)
        function cs = CascadeSizes(obj)
            cs = sum(getHistoryFailureSeq(obj) > 0, 2) - obj.ntrig;  % Number of failures per cascade simulation
        end

        % Plot the cascade sizes across simulations
        function plotCascadeSizes(obj)
            bar(obj.CascadeSizes)
            xlim([0, obj.NumSims + 1])
            set(gca, 'FontSize', 16)
            title('Cascade sizes')
            xlabel('Simulation index')
            ylabel('Number of failures')
        end

        % Compute the mean CPU time per step of the simulation
        function m = MeanCPUTimePerStep(obj)
            m = obj.TotalCPUTime/sum(obj.CascadeSizes);
        end

        % Get the total time spent on all simulations
        function t = TotalCPUTime(obj)
            t = sum(obj.CPUTime);  % Total CPU time used across all simulations
        end

        % Reset the simulation history
        function clearHistory(obj)
            obj.NumSims = 0;
            obj.CPUTime = [];
            obj.HistoryFailureSeq = spalloc(1, obj.nl, floor(0.1*obj.nl));  % Clear failure history
        end
        
    end
    
    methods (Access = public) 
        % Private helper functions that assist with simulation setup and calculations
        prepareInitialState(obj, dataset)
        updateMatrixB(obj)
        updateCompInfo(obj)
        computePowerFlow(obj)
        adjustPowerInComp(obj)
        nextLineFailure(obj,ovl)
    end
    
end