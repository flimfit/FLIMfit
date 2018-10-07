function estimate_irf_interface(t, data, T, analytical, default_path)

if any(data==0)
    warndlg('Decay contains zeros, please average over a larer region','Warning')
end

screen_pos = get(0,'ScreenSize');
pos = [100 100 screen_pos(3:4) - 200];

fh = figure('Name','Estimate IRF','NumberTitle','off','Menu','none','Toolbar','none','Position',pos);

layout = uix.VBox('Parent',fh);

n_chan = size(data,2);

tabs = uix.TabPanel('Parent',layout);

for i=1:n_chan
    ch_layout = uix.VBox('Parent',tabs);
    
    fit_box = uix.BoxPanel('Parent',ch_layout,'Title','Fit');
    fit_ax(i) = axes('Parent',fit_box);
    
    res_box = uix.BoxPanel('Parent',ch_layout,'Title','Residual');
    res_ax(i) = axes('Parent',res_box);
    
    titles{i} = ['Channel ' num2str(i)];
    ch_layout.Heights = [-2.5 -1];
end
tabs.TabTitles = titles;

button_layout = uix.HBox('Parent',layout);
uix.Empty('Parent',button_layout);
uicontrol(button_layout,'Style','pushbutton','String','Cancel','Callback', @(~,~) close(fh));
save_button = uicontrol(button_layout,'Style','pushbutton','String','Save IRF...','Enable','off','Callback',@save);
button_layout.Widths = [-1 200 200];
layout.Heights = [-1 30];

if analytical
    
    for i=1:n_chan
        tabs.Selection = i;
        [analytical_parameters(i), chi2(i)] = estimate_analytical_irf(t,data(:,i),T,fit_ax(i),res_ax(i));
    end
    
else
    
    for i=1:n_chan
        tabs.Selection = i;
        [irf(:,i), t_final, chi2(i)] = estimate_irf(t,data(:,i),T,fit_ax(i),res_ax(i));
    end
    
    valid = max(irf,[],2) > 1e-10;
    idx_start = find(valid,1);
    idx_end = find(valid,1,'last');
    
    irf = irf(idx_start:idx_end,:);
    t_final = t_final(idx_start:idx_end);
    
end


save_button.Enable = 'on';

    function save(~,~)
        
        if max(chi2) > 1.3
            h = warndlg({'The quality of fit produced with the estimated IRF is relatively low,',...
                'you might need to directly measure the IRF'},'Warning');
            waitfor(h);
        end
        
        if analytical
                        
            text = jsonencode(analytical_parameters);
            
            [file, path] = uiputfile({'*.json', 'JSON file (*.json)'},'Select file name',default_path);
            
            if file~=0
                f = fopen([path file],'w');
                fprintf(f,text);
                fclose(f);
                close(fh);
            end
        else
            
            dat = table();
            dat.t = t_final;
            for j=1:size(irf,2)
                dat.(['irf_ch' num2str(j)]) = irf(:,j);
            end
            
            [file, path] = uiputfile({'*.csv', 'CSV File (*.csv)'},'Select file name',default_path);
            if file~=0
                writetable(dat,[path file]);
                close(fh);
            end
        end
    end

end
