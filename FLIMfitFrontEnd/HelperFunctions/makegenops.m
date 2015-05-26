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
function makegenops
%MAKEGENOPS Make MEX files for generalized arithmetic operators.
%	MAKEGENOPS creates the MEX files from the source file genops.c
%	by calling mex with the appropriate complier directives.
%	MAKEGENOPS should be in the same directory as GENOPS.M and that
%	directory must contain a subdirectory, src, which contains
%	genops.c.

% Version: 1.0, 3 April 1999
% Author:  Douglas M. Schwarz
% Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

opdir = ['doubleops_' computer];
srcdir = 'src';

base = fileparts(which(mfilename));
doubleops = fullfile(base,opdir);
if ~exist(doubleops,'dir')
	mkdir(base,opdir)
end
atdir = fullfile(doubleops,'@double');
if ~exist(atdir,'dir')
	mkdir(doubleops,'@double')
end

fcns = {'plus','minus','times','rdivide','ldivide','power',...
		'eq','ne','lt','gt','le','ge'};

syms = {'PLUS_MEX','MINUS_MEX','TIMES_MEX','RDIVIDE_MEX','LDIVIDE_MEX',...
		'POWER_MEX','EQ_MEX','NE_MEX','LT_MEX','GT_MEX','LE_MEX','GE_MEX'};
for i = 1:length(fcns)
	disp(['Making ',fcns{i}])
	mex(fullfile(base,srcdir,'genops.c'),['-D',syms{i}],'-output',...
			fullfile(atdir,fcns{i}))
end
