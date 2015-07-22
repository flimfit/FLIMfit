function [results] = ShowResults2(folder, end_filter, groups, limI)

    if nargin < 4
        limI = nan;
    end

    results = {};

    figure(3);
    clf(3)
    set(gcf, 'Position', [1127, 26, 761, 327]);
    
    for g=1:length(groups)

        files = dir([folder groups{g} '*.pt3' end_filter '.mat']);


        for i=1:length(files)

            file_name = [folder files(i).name];
            mask_name = strrep(file_name, '.mat', '.png');
            
            load(file_name);

            if exist(mask_name, 'file')
                mask = imread(mask_name);
            else
                mask = zeros(size(r.Isum),'uint8');
            end
            
            r.mask = mask;
            
            results{g}{i} = r;
            names{g}{i} = files(i).name;

        end

%        names{g} = strrep(names{g}, '.pt3.mat', '');
        plot_results(results{g},names{g},g,length(groups),limI,groups{g});


    end
    
    figure(3);
    for i=1:2
        subplot(1,2,i)
        legend(groups)
        legend('boxoff')
    end
    
    tightfig
end


function plot_results(results,names,idx,nt,limI,group_name)

    d = [];
   
    n = length(results);
    n = min(n, 5);
    lim1 = [0.0 0.6];
    lim2 = [0.0 0.6];
    
        
    for j=1:n

        r = results{j};
        
        A_CFP{j} = r.A_CFP;
        A_GFP{j} = r.A_GFP; 
        E_CFP{j} = r.E_CFP; 
        E_GFP{j} = r.E_GFP; 
                
        sel = ~isnan(r.E_GFP);
        d = [d; [r.A_CFP(sel), r.A_GFP(sel), r.E_CFP(sel) r.E_GFP(sel) r.res(sel)]];
    end
    

    figure(3+2*idx-1);
    clf;
    set(gcf,'Position',[1016, 720, 1060, 241]);
    PlotMerged(E_CFP, A_CFP, lim1, limI)
    PlotMerged(E_CFP, A_CFP, lim1, limI)
    title('Rac1');
    set(gcf,'Name',names{j});
    tightfig;

    figure(3+2*idx);
    clf;
    set(gcf,'Position',[1016, 407, 1060, 241]);
    PlotMerged(E_GFP, A_GFP, lim2, limI);
    title('RhoA')
    set(gcf,'Name',names{j});
    tightfig;
    
%{
        subplot(3,n,j+2*n);
        imagesc(r.RAF);
        daspect([1 1 1]); set(gca,'YTick',[],'XTick',[]);
        caxis([0 2000]);
        title('RAF')
%}


    col(1) = 3;
    col(2) = 4;

    x{1} = linspace(0,2,100);
    x{2} = linspace(0,2,100);
    x{3} = linspace(0,1,100);
    x{4} = linspace(0,1,100);
    x{5} = linspace(0,0.1,100);

    label = {'A Rac1', 'A RhoA', 'Rac1', 'RhoA', 'residual'};

    set(0,'DefaultAxesFontSize',15,'DefaultTextFontSize',15);
    figure(3)

    %{
    subplot(nt,3,1+(idx-1)*3);

    [h,e] = hist3([d(:,col(1)) d(:,col(2))],[x(col(1)), x(col(2))]);
    imagesc(x{col(2)}, x{col(1)}, h)
    %daspect([1 1 1])
    set(gca,'YDir','normal')
    xlabel(label{col(2)});
    ylabel(label{col(1)});
    %}
    
    for k=3:4

        subplot(1,2,k-2);
        xx = x{k};
        [h,e] = histwv(d(:,k),d(:,k-2),min(xx),max(xx),length(xx));
        %sum(h.*xx')/sum(h)
        plot(xx,h/max(h));
        title(label{k})
        xlabel('FRET Efficency');
        ylabel('Frequency')
        xlim([0, 1]);
        set(gca,'Box','off','TickDir','out')
        hold on;
    end
    
end