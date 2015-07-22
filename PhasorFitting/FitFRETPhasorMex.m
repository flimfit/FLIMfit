function [Af,kf,Ff,rf] = FitFRETPhasorMex(p, I)
    
    global red_sel

    p = double(p);
    I = double(I);

    n = size(p,2);
    
    Af = nan([2,n]);
    kf = nan([2,n]);
    rf = nan([1,n]);
    Ff = nan([1,n]);
    
    for i=1:n

        if any(I(:,i) > 300) % && PhasorInEllipse(p(1,i), red_sel)
        
%            if (mod(i,100) == 0)
 %               disp(['About to fit: ' num2str(i)]);
  %          end

            if ~any(isnan(p(:,i)))
                xf = FRETPhasor(p(:,i), I(:,i));
                Af(:,i) = xf(1:2);
                Ff(i) = xf(3);
                kf(:,i) = xf(4:5);  
                rf(i) = xf(6);
            end
        
        end
        
    end
    
end