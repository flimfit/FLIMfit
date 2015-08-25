function [Af,kf,Ff,rf] = FitFRETPhasorMex(p, I)
    
    omega = 2*pi / 12500;

    p = double(p);
    I = double(I);

    n = size(p,2);
    
    Af = nan([2,n]);
    kf = nan([2,n]);
    rf = nan([1,n]);
    Ff = nan([1,n]);
    
    sel = (sum(I,1) > 100) & ~any(isnan(p),1);
    
    p = p(:,sel);
    I = I(:,sel);
    
    
    xf = FRETPhasor(p,I);
    
    Af(:,sel) = xf(1:2,:);
    Ff(:,sel) = xf(3,:);
    kf(:,sel) = xf(4:5,:);  
    rf(:,sel) = xf(6,:);
    
    %{
    tau = 1/omega * imag(p) ./ real(p);
    
    Af(:,sel) = flipud(I(2:3,:));
    kf(:,sel) = flipud(tau(2:3,:));
    %}
end