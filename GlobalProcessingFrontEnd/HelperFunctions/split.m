function l = split(d,s)
%L=SPLIT(S,D) splits a string S delimited by characters in D.  Meant to
%             work roughly like the PERL split function (but without any
%             regular expression support).  Internally uses STRTOK to do 
%             the splitting.  Returns a cell array of strings.
%
%Example:
%    >> split('_/', 'this_is___a_/_string/_//')
%    ans = 
%        'this'    'is'    'a'    'string'   []
%
%Written by Gerald Dalley (dalleyg@mit.edu), 2004

l = {};
while (length(s) > 0)
    [t,s] = strtok(s,d);
    l = {l{:}, t};
end
