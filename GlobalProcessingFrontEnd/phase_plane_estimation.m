function [tau] = phase_plane_estimation(t_f,g,f,N)
    %#codegen
    
    n_f = length(t_f);
    
    F = zeros(n_f,N);
    G = zeros(n_f,N);
    
    F(:,1) = cumtrapz(t_f,f,1);
    G(:,1) = cumtrapz(t_f,g,1);
    
    for i=2:N
        F(:,i) = cumtrapz(t_f,F(:,i-1),2);
        G(:,i) = cumtrapz(t_f,G(:,i-1),2);
    end

    A = [-F G];

    x = pinv(A)*f;
   
    %res = (A*x-f);
    %S = nansum(res.^2)/(n_f-N);
    
    c = [1; x(1:N)];
    
    c = flipud(c);
    alt = double(((-1).^(0:N))');
    tau = roots(c.*alt);
        
end