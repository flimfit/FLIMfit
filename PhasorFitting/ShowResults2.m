function results = ShowResults2(folder, end_filter, groups)

    results = {};

    clf(3)
    
    for g=1:length(groups)

        files = dir([folder groups{g} '*' end_filter '.mat']);


        for i=1:length(files)

            load([folder files(i).name]);

            results{g}{i} = r;
            names{g}{i} = files(i).name;

        end

        names{g} = strrep(names{g}, '.pt3.mat', '');

        plot_results(results{g},names{g},g,length(groups));


    end
end

function plot_results(results,names,idx,nt)

    d = [];
   
    n = length(results);
    n = min(n, 5);
    lim1 = [0.0 0.4];
    lim2 = [0.0 0.6];
    
    figure(3+idx);
    clf;
    for j=1:n

        r = results{j};

        subplot(2,n,j);
        imagesc(r.E_CFP);
        PlotMerged(r.E_CFP, r.A_CFP, lim1)
        title(names{j}, 'Interpreter', 'none');

        subplot(2,n,j+n);
        imagesc(r.E_GFP);
        PlotMerged(r.E_GFP, r.A_GFP, lim2);
        title('GFP')

        sel = ~isnan(r.E_GFP);
        d = [d; [r.A_CFP(sel), r.A_GFP(sel), r.E_CFP(sel) r.E_GFP(sel) r.res(sel)]];
    end


    col(1) = 3;
    col(2) = 4;

    x{1} = linspace(0,2,100);
    x{2} = linspace(0,2,100);
    x{3} = linspace(0,1,100);
    x{4} = linspace(0,1,100);
    x{5} = linspace(0,0.1,100);

    label = {'A Rac', 'A Rho', 'E Rac', 'E Rho', 'residual'};

    figure(3)
    subplot(nt,3,1+(idx-1)*3);

    [h,e] = hist3([d(:,col(1)) d(:,col(2))],[x(col(1)), x(col(2))]);
    imagesc(x{col(2)}, x{col(1)}, h)
    %daspect([1 1 1])
    set(gca,'YDir','normal')
    xlabel(label{col(2)});
    ylabel(label{col(1)});

    for k=3:4

        subplot(nt,3,k-1);
        xx = x{k};
        [h,e] = histwv(d(:,k),d(:,k-2),min(xx),max(xx),length(xx));
        plot(xx,h/max(h));
        xlabel(label{k});
        ylim([0, 1.1]);
        xlim([0, 1]);
        hold on;
    end
end