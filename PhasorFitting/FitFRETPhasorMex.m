function [Af,kf] = FitFRETPhasorMex(p, I)

    p = double(p);
    I = double(I);

    Af = zeros(size(p));
    kf = zeros(size(p));

    parfor i=1:size(p,2)

        if (mod(i,100) == 0)
            disp(['About to fit: ' num2str(i)]);
        end

        if ~any(isnan(p(:,i)))
            xf = FRETPhasor(p(:,i), I(:,i));

            Af(:,i) = xf(1:2);
            kf(:,i) = xf(3:4);  
        end
        
    end

    disp('Done');
    
end