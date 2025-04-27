classdef Timer
    % A minimal but convenient timer class for measuring the elapsed time in the code
    %
    % Usage:
    %     timer = Timer(message, multiline);
    %     timer.stop()
    %
    %  Set multiline = true if output printout is expected during usage

    properties (GetAccess = public, SetAccess = private)
        start_datetime
        multiline
    end

    methods (Access = public)
        function obj = Timer(message, multiline)
            if nargin < 2
                multiline = false;
            end
            obj.multiline = multiline;
            if nargin < 1
                message = 'Starting a timer';
            end
            if obj.multiline
                fprintf('%s...\n', message);
            else
                fprintf('%s...', message);
            end
            obj.start_datetime = datetime();
        end

        function stop(obj)
            if obj.multiline
                fprintf('Done (elapsed time: %s)\n', datetime() - obj.start_datetime);
            else
                fprintf(' done (elapsed time: %s)\n', datetime() - obj.start_datetime);
            end
        end
    end
end