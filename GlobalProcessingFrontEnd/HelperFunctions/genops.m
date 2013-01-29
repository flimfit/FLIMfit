%{
Copyright (c) 2006, Douglas M. Schwarz
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are 
met:

    * Redistributions of source code must retain the above copyright 
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in 
      the documentation and/or other materials provided with the distribution
      
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
%}

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
