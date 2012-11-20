function [M, S, N] = combine_stats(m,s,n)
    % Combine a number of means and standard deviations, will be combined along rows
     
    include = ~isnan(sum(m,1));
    
    n = n(:,include);
    m = m(:,include);
    s = s(:,include);
    
    N = sum(n);
    
    M = sum(n .* m,2) / N;

    S = sqrt(sum( n .* s.*s, 2) / N); 
        
end