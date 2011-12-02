function sim_plot_beta_map(est_beta_map,avg,tau2,lim,offset)

if nargin < 4
    offset = 0;
end

Nh = size(est_beta_map,2);
Nw = size(est_beta_map,1);

clf();
h = gcf();
set(h,'position',[0 0 800 800]);
ha = tight_subplot(h,Nh*Nw,Nh,Nw,[5 5],[45 5],[45 60],'pixels');

k = 0;
for j=1:Nh
    for i=1:Nw
        k = k + 1;
        disp([i j])
        imagesc(squeeze(est_beta_map{i,j}-offset),'Parent',ha(k));
        set(ha(k),'YTick',[]);
        set(ha(k),'XTick',[]);
        caxis(ha(k),lim);
        if j == Nh
            label = num2str(avg(i));
            xlabel(ha(k),label)
            if i == ceil(Nw/2)
                xlabel(ha(k),{label; 'Photons/px'})
            end
        end
        if i == 1
            label = num2str(3750-tau2(j));
            ylabel(ha(k),label)
            if j == ceil(Nh/2)
                ylabel(ha(k),{'\tau_{D}-\tau_{DA}';label})
            end
        elseif i==Nw
            w=15;
            a=5;
            pos=get(ha(k),'position');
            colorbar('peer',ha(k),'location','EastOutside','units','pixels','position',[pos(1)+pos(3)+5 pos(2)+a w pos(4)-a*2]);
            set(ha(k),'position',pos);
        end
    end
end