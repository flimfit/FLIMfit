% A progress dialog to notify the user of the status an ongoing operation.
% Unlike waitbar, the progress dialog is automatically closed when the
% operation is interrupted by the user or an error occurs.
%
% See also: waitdialog, waitbar

% Copyright 2009-2010 Levente Hunyadi
classdef ProgressDialog < UIControl
    properties (Dependent)
        Control;
    end
    properties
        % Completion status p with 1 >= p >= 0, or empty if indeterminate.
        FractionComplete = 0;
        % Status message shown to the user.
        StatusMessage = 'Please wait...';
        % Indeterminate completion status.
        % Indeterminate status is intended for operations whose completion
        % status is unknown or cannot be computed.
        Indeterminate = false;
        Implementation = 'java';
    end
    properties (Access = private)
        Dialog;
    end
    methods
        function obj = ProgressDialog(varargin)
            obj = obj@UIControl(varargin{:});
        end
        
        function obj = Instantiate(obj, parent) %#ok<INUSD>
            switch obj.Implementation
                case 'matlab'
                    impl = false;
                case 'java'
                    impl = true;
            end
            obj.Dialog = progressbar([], obj.FractionComplete, obj.StatusMessage, impl);
        end
        
        function control = get.Control(obj)
            control = obj.Dialog;
        end
        
        function set.FractionComplete(obj, x)
            if ~isempty(x)
                validateattributes(x, {'numeric'}, {'nonnegative','real','scalar'});
            end
            obj.FractionComplete = x;
            if obj.TestForUserInterrupt()
                callererror('gui:ProgressDialog', 'Operation terminated by user.');
            end
            obj.UpdateDialog();
        end
        
        function set.StatusMessage(obj, message)
            if ~isempty(message)
                validateattributes(message, {'char'}, {'nonempty','row'});
            end
            obj.StatusMessage = message;
            if obj.TestForUserInterrupt()
                callererror('gui:ProgressDialog', 'Operation terminated by user.');
            end
            obj.UpdateDialog();
        end
        
        function set.Indeterminate(obj, tf)
            validateattributes(tf, {'logical'}, {'scalar'});
            obj.Indeterminate = tf;
            obj.UpdateDialog();
        end
        
        function delete(obj)
            if ishandle(obj.Dialog)
                delete(obj.Dialog);
            end
        end
        
        function uiwait(obj)
            uiwait(obj.Dialog);
        end
    end
    methods (Access = private)
        function tf = TestForUserInterrupt(obj)
            if ~ishandle(obj.Dialog)  % dialog has been closed by user
                obj.Dialog = [];
                tf = true;
            else
                tf = false;
            end
        end
        
        function UpdateDialog(obj)
            if obj.Indeterminate
                r = [];
            else
                r = obj.FractionComplete;
            end
            progressbar(obj.Dialog, r, obj.StatusMessage);
            drawnow;
        end
    end
end
