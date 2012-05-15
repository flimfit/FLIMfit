function stateout = genops(newstate)
%GENOPS Turn generalized arithmetic double operators on or off.
%
%	GENOPS will toggle the state of the operators.
%
%	GENOPS(1) or GENOPS ON will turn them on.
%
%	GENOPS(0) or GENOPS OFF will turn them off.
%
%	S = GENOPS(...) will return the previous state of the operators,
%	0 for OFF and 1 for ON, and set the state according to the argument.
%
%	S = GENOPS with no argument will return the state and leave it
%	unchanged.

% Version: 1.0, 3 April 1999
% Author:  Douglas M. Schwarz
% Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

genopsfunpath = fullfile(fileparts(which(mfilename)),['doubleops_' computer]);
state = ~isempty(findstr(path,genopsfunpath));

if nargin == 0
	if nargout > 0
		stateout = state;
		return
	end
	newstate = ~state;
else
	if ischar(newstate)
		if strcmpi(newstate,'on')
			newstate = 1;
		elseif strcmpi(newstate,'off')
			newstate = 0;
		else
			error(['Unknown command option ''',newstate,''''])
		end
	end
end

if ~exist(genopsfunpath)
    mex -setup
    makegenops
end


if newstate ~= state
	if newstate
		addpath(genopsfunpath,'-begin')
	else
		rmpath(genopsfunpath)
	end
end

if nargin == 0
	if newstate
		disp('Generalized arithmetic operators are ON.')
	else
		disp('Generalized arithmetic operators are OFF.')
	end
end

if nargout > 0
	stateout = state;
end
