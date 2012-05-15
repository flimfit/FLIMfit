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
