function m = trimstd(x,percent,flag,dim)
%TRIMMEAN Trimmed mean.
%   M = TRIMMEAN(X,PERCENT) calculates the trimmed mean of the values in X.
%   For a vector input, M is the mean of X, excluding the highest and
%   lowest K data values, where K=N*(PERCENT/100)/2 and where N is the
%   number of values in X.  For a matrix input, M is a row vector
%   containing the trimmed mean of each column of X.  For N-D arrays,
%   TRIMMEAN operates along the first non-singleton dimension.  PERCENT is
%   a scalar between 0 and 100.
%
%   M = TRIMMEAN(X,PERCENT,FLAG) controls how to trim when K is not an
%   integer.  FLAG can be chosen from the following:
%
%      'round'    Round K to the nearest integer (round to a smaller
%                 integer if K is a half integer).  This is the default.
%      'floor'    Round K down to the next smaller integer.
%      'weight'   If K=I+F where I is the integer part and F is the
%                 fraction, compute a weighted mean with weight (1-F) for
%                 the (I+1)th and (N-I)th values, and full weight for the
%                 values between them.
%
%   M = TRIMMEAN(X,PERCENT,FLAG,DIM) takes the trimmed mean along dimension
%   DIM of X.
%
%   The trimmed mean is a robust estimate of the sample location.
%
%   TRIMMEAN treats NaNs as missing values, and removes them.
%
%   See also MEAN, NANMEAN, IQR.

%   References:
%     [1] Wilcox, Rand R. "Introduction to Robust Estimation and
%         Hypothesis Testing." New York: Academic Press. 2005.
%     [2] Stigler, Stephen M. "Do robust estimators work with real data?"
%         Annals of Statistics, Vol. 5, No. 6, 1977, pp. 1055-1098.    

%   Copyright 1993-2011 The MathWorks, Inc.
%   $Revision: 1.1.8.3 $  $Date: 2011/05/09 01:27:07 $

if nargin < 2
    error(message('stats:trimmean:TooFewInputs'));
elseif ~isscalar(percent) || percent >= 100 || percent < 0
    error(message('stats:trimmean:InvalidPercent'));
end

% Be flexible about syntax, so dim/flag may be in reverse order
if nargin<3
    flag = 'round';
    dim = [];
elseif nargin<4
    if isnumeric(flag)
        dim = flag;
        flag = 'round';
    else
        dim = [];
    end
end
if isnumeric(flag)
    temp = dim;
    dim = flag;
    flag = temp;
end

if isempty(dim)
    % The output size for [] is a special case, handle it here.
    if isequal(x,[]), m = NaN; return; end;

    % Figure out which dimension to work along.
    dim = find(size(x) ~= 1, 1);
    if isempty(dim), dim = 1; end
end

if ischar(flag) && (isempty(flag) || isequal(lower(flag),'round'))
    F = @roundtrim;
elseif ischar(flag) && (isempty(flag) || isequal(lower(flag),'weighted'))
    F = @wtdtrim;
elseif ischar(flag) && isequal(lower(flag),'floor')
    F = @unwtdtrim;
else
    error(message('stats:trimmean:BadFlag'))
end

% Keep track of columns that were all missing data, or length zero.
allmissing = all(isnan(x),dim);

% Permute dimensions so we are working along columns
xdims = ndims(x);
if dim>1
    perm = [dim:max(xdims,dim) 1:dim-1];
    x = permute(x,perm);
else
    perm = [];
end

% Sort each column, get desired output size before inverse permutation
x = sort(x,1);
sz = size(x);
sz(1) = 1;

if ~any(isnan(x(:)))
    % No missing data, operate on all columns at once
    n = size(x,1);
    [m,alltrimmed] = F(x,n,percent,sz);
else
    % Need to loop over columns
    m = NaN(sz,class(x));
    alltrimmed = false(sz);
    for j = 1:prod(sz(2:end))
        n = find(~isnan(x(:,j)),1,'last');
        [m(j),alltrimmed(j)] = F(x(:,j),n,percent,[1 1]);
    end
end

% Permute back
m = reshape(m,sz);
if ~isempty(perm)
    m = ipermute(m,perm);
    alltrimmed = ipermute(alltrimmed,perm);
end

% Warn if everything was trimmed, but not if all missing to begin with.
alltrimmed = (alltrimmed & ~allmissing);
if any(alltrimmed(:))
    if all(alltrimmed(:))
        warning(message('stats:trimmean:NoDataRemaining'));
    else
        warning(message('stats:trimmean:NoDataRemainingSomeColumns'));
    end
end

% --- Trim complete observations only, no weighting, rounding
function [m,alltrimmed] = roundtrim(x,n,percent,sz)
k = n*percent/200;
k0 = round(k - eps(k));
if ~isempty(n) && n>0 && k0<n/2
    m = std(x((k0+1):(n-k0),:),1);
    alltrimmed = false;
else
    m = NaN(sz,class(x));
    alltrimmed = true;
end

% --- Trim complete observations only, no weighting
function [m,alltrimmed] = unwtdtrim(x,n,percent,sz)
k0 = floor(n*percent/200);
if ~isempty(n) && n>0 && k0<n/2
    m = std(x((k0+1):(n-k0),:),1);
    alltrimmed = false;
else
    m = NaN(sz,class(x));
    alltrimmed = true;
end

% --- Weight observations to achieve desired percentage trimming
function [m,alltrimmed] = wtdtrim(x,n,percent,sz)
k = n*percent/200;     % desired k to trim
k0 = floor(k);         % integer versiom
f = 1+k0-k;            % fraction to use for weighting
if ~isempty(n) && n>0 && (k0<n/2 || f>0)
    m = (sum(x((k0+2):(n-k0-1),:),1) + f*x(k0+1,:) + f*x(n-k0,:)) ...
        / (max(0,n-2*k0-2) + 2*f);
    alltrimmed = false;
else
    m = NaN(sz,class(x));
    alltrimmed = true;
end
