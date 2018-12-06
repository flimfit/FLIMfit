function [irf_final,t_final] = estimate_irf_interface(t, data, T, default_path)

    screen_pos = get(0,'ScreenSize');
    pos = [100 100 screen_pos(3:4) - 200];

    fh = figure('Name','Estimate IRF','NumberTitle','off','Menu','none','Toolbar','none','Position',pos);

    layout = uix.VBox('Parent',fh);
    fit_layout = uix.VBox('Parent',layout);
    fit_box = uix.BoxPanel('Parent',fit_layout,'Title','Fit');
    fit_ax = axes('Parent',fit_box);

    res_box = uix.BoxPanel('Parent',fit_layout,'Title','Residual');
    res_ax = axes('Parent',res_box);

    fit_layout.Heights = [-2.5 -1];

        
    button_layout = uix.HBox('Parent',layout);
    uix.Empty('Parent',button_layout);
    uicontrol(button_layout,'Style','pushbutton','String','Cancel','Callback', @(~,~) close(fh));
    save_button = uicontrol(button_layout,'Style','pushbutton','String','Save IRF...','Enable','off','Callback',@save);
    button_layout.Widths = [-1 200 200];
    layout.Heights = [-1 30];

    if size(data,2) == 2
        [irf, t_final, chi2] = estimate_irf_polarised(t,data,T,fit_ax,res_ax);
    else
        [irf, t_final, chi2] = estimate_irf(t,data,T,fit_ax,res_ax);
    end
    
    valid = max(irf,[],2) > 1e-10; 
    idx_start = find(valid,1);
    idx_end = find(valid,1,'last');
    
    irf = irf(idx_start:idx_end,:);
    t_final = t_final(idx_start:idx_end);

    
    save_button.Enable = 'on';
    
    function save(~,~)
        dat = table();
        dat.t = t_final;
        for j=1:size(irf,2)
            dat.(['irf_ch' num2str(j)]) = irf(:,j);
        end

        if max(chi2) > 1.3
           h = warndlg({'The quality of fit produced with the estimated IRF is relatively low,',...
                    'you might need to directly measure the IRF'},'Warning');
           waitfor(h);
        end
        
        [file, path] = uiputfile({'*.csv', 'CSV File (*.csv)'},'Select file name',default_path);
        if file~=0
            writetable(dat,[path file]);
            close(fh);
        end
    end

end
