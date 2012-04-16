function [counts_per_photon offset] = determine_photon_stats(data)
    
    global fh_ps;
    
    if isempty(fh_ps)
        fh_ps = figure();
    else
        figure(fh_ps);
    end
    
    n_req = 5000;

    sz = size(data);
    data = reshape(data,[sz(1) sz(3)]);
    
    I = squeeze(sum(data,1));
    
    %n = s(3);
    %pt = n_req/n*100;
    lim = prctile(I(:),[25 75]);
    sel = I >= lim(1) & I <= lim(2);
    data = data(:,sel);

    data = data(2:end,:);
    
    subplot(1,1,1);

    opt = optimset();%;'PlotFcns',{@optimplotfval});

    o = fminsearch(@objt,[1 0],opt);

    counts_per_photon = o(1);
    offset = o(2);
        
    function r = objt(m) 

        tr = (data-m(2))/m(1);
        antr = 2*sqrt(tr+3/8);
        s = std(antr,0,2);
        mn = mean(antr,2);
        r = norm(s-1);
        
        hold off;
        plot(mn,ones(size(s)),'k'); 
        %ylim([0.8 1.2]);
        hold on;
        plot(mn,s.*s,'o');
        ylabel('Variance');
        xlabel('Corrected Photon Count');
        title(['N = ' num2str(m(1)) ', Z = ' num2str(m(2))]);
        drawnow;
    end

end

