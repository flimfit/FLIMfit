
function icy_closeall(close_matlab_figures_too)
% icy_closeall()
% icy_closeall(close_matlab_figures_too)
%
% Close all the viewers that belong to the current session.
%
% The usual Matlab figures can also be closed by the command, by setting the
% optional 'close_matlab_figures_too' flag to true. This is the default behavior
% if the flag is not specified.

% Optional parameter
if(~exist('close_matlab_figures_too', 'var'))
	close_matlab_figures_too = true;
end

% Execute the command
icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'closeall');

% Close the matlab figures
if(close_matlab_figures_too)
	close all;
end
