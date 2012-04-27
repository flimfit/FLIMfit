function estimate_irf_background(obj)
    
    %> Estimate the IRF background level.
    
    % Try to fit to two gaussians, one for peak and one for background. 
    % Theoretically not as good as fitting to a gauss + constant but seems 
    % to converge better. In general the background just has a very large 
    % sigma. The background is the mean of the smaller 'peak'

    for i=1:size(obj.irf,2)

        ir = double(obj.irf(:,i));
        
        if sum(ir==0) > 0.5 * length(ir)
            bg(i) = 0;
        else
            gauss_fit = gmdistribution.fit(ir,2,'Replicates',10);
            bg(i) = min(gauss_fit.mu); %#ok
        end
        
    end

    obj.irf_background = max(bg);
    
end
