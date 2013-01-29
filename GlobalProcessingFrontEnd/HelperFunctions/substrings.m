%{
Copyright (c) 2010, John D'Errico
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

function strs = substrings(str,nsub,uniqueflag)
% substrings: extract all substrings of a given length from a vector
% usage: strs = substrings(str,nsub)
% usage: strs = substrings(str,nsub,uniqueflag)
%
%
% arguments: (input)
%  str - any vector string, of any class.
%
%  nsub - scalar, positive integer - specifies the length
%        of the substrings to be generated
%
%  uniqueflag - (OPTIONAL) scalar boolean flag that
%        specifies if the result will be allowed to
%        contain duplicate entries, or will only
%        those unique substrings be returned.
%
%        uniqueflag == 0 --> return EVERY substring
%            from str. This array will not be sorted.
%
%        uniqueflag == 1 --> Only the unique (sorted)
%            list of substrings will be generated.
%            This array will be sorted.
%
% arguments: (output)
%  strs - a array of sub-strings, one row for each
%        substring found in str.
%
%        Note: substrings(str,1) is the same as
%            unique(substrings(str),'rows')
%
%
% Example:
%  bases = 'acgt';
%  str = bases(ceil(rand(1,20)*4))
% str =
% attcgcgtgcctagatgttt
%
% % Find ALL substrings, replicates are allowed.
% substrings(str,2)
% ans =
% at
% tt
% tc
% cg
% gc
% cg
% gt
% tg
% gc
% cc
% ct
% ta
% ag
% ga
% at
% tg
% gt
% tt
% tt
%
% % Find the set of distinct, unique substrings
% substrings(str,2,1)
% ans =
% ag
% at
% cc
% cg
% ct
% ga
% gc
% gt
% ta
% tc
% tg
% tt
%
% See also: strtok, cellstr, strfun, allwords
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release date: 4/7/2010

% test for problems.
% first, verify that str is a vector.
if ~isvector(str)
  error('SUBSTRINGS:nonvectorinput','str must be a vector')
end
if nargin > 3
  error('SUBSTRINGS:toomanyargs', ...
    'No more than two arguments allowed')
elseif nargin < 1
  help substrings
  return
end

if (nargin < 3) || isempty(uniqueflag)
  uniqueflag = 0;
elseif ~ismember(uniqueflag,[0 1])
  error('SUBSTRINGS:improperarg', ...
    'uniqueflag must be 0 or 1 if supplied.')
end

if nargin < 2
  error('SUBSTRINGS:insufficientargs', ...
    'At least two arguments must be supplied.')
end
if isempty(nsub) || ~isnumeric(nsub) || (nsub <= 0) || (nsub ~= round(nsub))
  error('SUBSTRINGS:improperarg', ...
    'nsub must be positive, integer, scalar, and numeric.')
end

% the number of elements in str
n = length(str);

% empty begets empty, but also if nsub is longer than n
% we must return empty.
if isempty(str) || (nsub > n)
  strs = [];
  return
elseif n == nsub
  % special case, with only one substring
  strs = str;
  return
elseif nsub == 1
  % special case, substrings of length 1
  strs = reshape(str,[],1);
  % do we get the unique elements?
  if uniqueflag
    strs = unique(strs);
  end
  return
end

% ensure that str is a column vector
str = str(:);

% create the indices of all substrings of
% the given length
ind = bsxfun(@plus,(0:(n - nsub))',1:nsub);
strs = str(ind);

% do we need to make them unique?
if uniqueflag
  strs = unique(strs,'rows');
end




