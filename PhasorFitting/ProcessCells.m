function [results, cells] = ProcessCells(folder, end_filter, groups, group_labels)

    if nargin < 4
        group_labels = groups;
    end

    results = {};
    cells = {};
    
    for g=1:length(groups)

        files = dir([folder groups{g} '*.pt3' end_filter '.mat']);

        for i=1:length(files)

            file_name = [folder files(i).name];
            mask_name = strrep(file_name, [end_filter '.mat'], '.png');
            
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

        cells{g} = process_regions(results{g});

    end
    
    loc = {'Membrane', 'Cytoplasm'};
    
    for k=1:2
        X = struct();
        G = struct();
        B = struct();
        E = struct();
        fields = fieldnames(cells{g}{k});

        for j=1:length(fields)
            X.(fields{j}) = [];
            G.(fields{j}) = [];
        end

        for i=1:length(cells)
            for j=1:length(fields)
                
                data = cells{i}{k}.(fields{j});
                
                B.(fields{j})(i) = nanmean(data);
                E.(fields{j})(i) = nanstd(data) / sqrt(length(data)-1);
                X.(fields{j}) = [X.(fields{j}) data];
                G.(fields{j}) = [G.(fields{j}) ones(size(data)) * i];
            end
        end

        figure(16)
        ax = subplot(1,4,k);
        boxplot(ax, X.E_CFP,G.E_CFP,'labels',group_labels);
        ylabel(ax,'FRET Efficiency')
        ylim(ax,[0 0.5])
        title(ax,['Rac1 ' loc{k}])
        set(ax,'Box','off','TickDir','out');
        
        ax = subplot(1,4,k+2);
        boxplot(ax,X.E_GFP,G.E_GFP,'labels',group_labels);
        ylim(ax,[0 0.5]);
        ylabel(ax,'FRET Efficiency')
        title(ax,['RhoA ' loc{k}])
        set(ax,'Box','off','TickDir','out');
        
        
        figure(17);
        ax = subplot(1,4,k); 
        barwitherr(ax,E.E_CFP,B.E_CFP,'w')
        set(ax,'XTickLabel',group_labels);
        ylabel(ax,'FRET Efficiency')
        ylim(ax,[0.0 0.3])
        title(ax,['Rac1 ' loc{k}]);
        set(ax,'Box','off','TickDir','out');
        
        ax = subplot(1,4,k+2);
        barwitherr(ax,E.E_GFP,B.E_GFP,'w')
        set(ax,'XTickLabel',group_labels);

        ylim(ax,[0.0 0.4])
        ylabel(ax,'FRET Efficiency')
        title(ax,['RhoA ' loc{k}])
        set(ax,'Box','off','TickDir','out');
        
    
    end
    
end

function cells = process_regions(r)

    cells{1} = struct('A_CFP',[],'A_GFP',[],'E_CFP',[],'E_GFP',[]);
    cells{2} = cells{1};
    
    for j=1:length(r)
        for k=1:2
            L = bwlabel(r{j}.mask==k);
            nL = max(L(:));

            for i=1:nL
                seg = L==i ;
                cells{k}.A_CFP(end+1) = nanmean(r{j}.A_CFP(seg));
                cells{k}.A_GFP(end+1) = nanmean(r{j}.A_GFP(seg));
                cells{k}.E_CFP(end+1) = nanmean(r{j}.E_CFP(seg).*r{j}.A_CFP(seg)) / cells{k}.A_CFP(end);
                cells{k}.E_GFP(end+1) = nanmean(r{j}.E_GFP(seg).*r{j}.A_GFP(seg)) / cells{k}.A_GFP(end);
            end
        end
    end
    
end




