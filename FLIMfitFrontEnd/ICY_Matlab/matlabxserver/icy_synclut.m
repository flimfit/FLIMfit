
function icy_synclut(h_master, varargin)
% icy_synclut(h_master, h_slave)
% icy_synclut(h_master, h_slave1, h_slave2)
% icy_synclut(h_master, h_slave1, h_slave2, ...)
% 
% Copy the look-up table (i.e. the color map) of the figure corresponding to
% 'h_master' to the ones corresponding to 'h_slave1', 'h_slave2', etc...

% Extract the list of slave figures to synchronize
nb_slaves = length(varargin);
h_slaves  = zeros(nb_slaves, 1);
for k=1:length(varargin)
	h_slaves(k) = varargin{k};
end

% Execute the command
args_in.h_master = int32(h_master);
args_in.h_slaves = int32(h_slaves);
icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'synclut', args_in);
