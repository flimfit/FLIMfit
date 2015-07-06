function [Af,kf,rf] = FitFRETPhasorMex(p, I)

    p = double(p);
    I = double(I);

    n = size(p,2);
    
    Af = zeros([2,n]);
    kf = zeros([2,n]);
    rf = zeros([1,n]);

    parfor i=1:n

        if sum(I(:,i),1) > 500
        
            if (mod(i,100) == 0)
                disp(['About to fit: ' num2str(i)]);
            end

            if ~any(isnan(p(:,i)))
                xf = FRETPhasor(p(:,i), I(:,i));

                Af(:,i) = xf(1:2);
                kf(:,i) = xf(3:4);  
                rf(i) = xf(5);
            end
        
        else
            
            Af(:,i) = nan;
            kf(:,i) = nan;
            rf(i) = nan;
            
        end
        
    end

    disp('Done');
    
end