function s = mat2struct(x,fields,dim,varargin)
%MAT2STRUCT Convert array to structure array.
%   S = MAT2STRUCT(X,FIELDS,DIM,M,N) converts the array X into
%   the structure S by folding the dimension DIM of X into fields of
%   S.  SIZE(X,DIM) must match the number of field names in FIELDS.
%   FIELDS can be a character array or a cell array of strings.
%
%    X is an array of size [ROW COL], M is the 
%   vector of row sizes (must sum to ROW) and N is the vector of column 
%   sizes (must sum to COL). The elements of M and N determine the size of
%   each cell in X by satisfying the following formula for I = 1:LENGTH(M)
%   and J = 1:LENGTH(N),
%
%       SIZE(X{I,J}) == [M(I) N(J)]
%
%   Example:
%     X = [1 2 3 4; 5 6 7 8; 9 10 11 12];
%     f = {'category','height','name'};
%     s = mat2struct(X,f,1,[1 1 1],4);
%
%   See also STRUCT2CELL, FIELDNAMES.

%   Copyright 2004 Stefano Gianoli, ETH Zurich
%   gianoli@chem.ethz.ch
%   $Date: 2004/06/15$
%   

c = mat2cell(x,varargin{:});
s = cell2struct(c,fields,dim);
