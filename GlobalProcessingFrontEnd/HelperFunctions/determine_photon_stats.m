function [counts_per_photon offset] = determine_photon_stats(data)
    
    figure();
    ax = axes();
    
    n_req = 1000;

    sz = size(data);
    data = reshape(data,[sz(1) sz(3)*sz(4)]);
    
    I = squeeze(sum(data,1));
    
    n = length(I);
    
    frac = n_req/n/2;

    N = 10;
    
    adj = linspace(0.2,0.8,N);
    
    h = waitbar(0,'Computing...');
    w = [];
    for i=1:N
 
        centre = adj(i);
        
        Q = quantile(I,[centre-frac,centre+frac]); 
 
        sel = I >= (Q(1)) & I <= (Q(2));
        
       
        w(i) = Q(2)-Q(1);
        
        sel_data = data(:,sel);   
        sel_data = sel_data(2:end,:);

        c = 0;
        [o,f] = fminsearch(@objt,[1 1]);

        counts_per_photon(i) = o(1);
        offset(i) = o(2);
        waitbar(i/N,h);
    end
    close(h);

    st = ['Counts per photon = ' num2str(mean(counts_per_photon),'%.2f') ' +/- ' num2str(std(counts_per_photon),2)];
    disp(st);
    disp(['           Offset = ' num2str(mean(offset),'%.2f') ' +/- ' num2str(std(offset),2)])

    
    hold(ax,'off')
    plot(ax,adj,counts_per_photon);
    xlabel(ax,'Sample')
    ylabel(ax,'Counts per photon');
    title(ax,st)
    
    
    counts_per_photon = mean(counts_per_photon);
    offset = mean(offset);
    
    function r = objt(m) 

        tr = (sel_data-m(2))/m(1);
        antr = 2*sqrt(tr+3/8);
        s = std(antr,0,2);
        mn = mean(antr,2);
        r = norm(s-1).^2;
                
        if mod(c,10) == 0
        hold(ax,'off');
        plot(ax,mn,ones(size(s)),'k'); 
        %ylim([0.8 1.2]);
        hold(ax,'on');
        plot(ax,mn,s.*s,'o');
        ylabel(ax,'Variance');
        xlabel(ax,'Corrected Photon Count');
        title(ax,['N = ' num2str(m(1)) ', Z = ' num2str(m(2))]);
        drawnow;
        end
        c = c + 1;
    end

end

