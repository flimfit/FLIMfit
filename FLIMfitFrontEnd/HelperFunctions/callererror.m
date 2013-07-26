% Produce error in the context of the caller function.
% The function throws a MatLab exception that lacks the stack frame of the
% caller function.

% Copyright 2009 Levente Hunyadi
function callererror(identifier, message, varargin)

if nargin > 2
    text = sprintf(message, varargin{:});
else
    text = message;
end

errorstruct = struct( ...
    'message', text, ...
    'identifier', identifier, ...
    'stack', dbstack(2));  % remove the context of (1) the caller function and (2) this function
error(errorstruct);
