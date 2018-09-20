function estimate_polarisation_resolved_irf_interface(t, data, T, default_path)

if any(data==0)
    warndlg('Decay contains zeros, please average over a larer region','Warning')
end

screen_pos = get(0,'ScreenSize');
pos = [100 100 screen_pos(3:4) - 200];

fh = figure('Name','Estimate IRF','NumberTitle','off','Menu','none','Toolbar','none','Position',pos);

layout = uix.VBox('Parent',fh);

n_chan = size(data,2);
assert(n_chan == 2)

ch_layout = uix.VBox('Parent',layout);

fit_box = uix.BoxPanel('Parent',ch_layout,'Title','Fit');
fit_ax = axes('Parent',fit_box);

res_box = uix.BoxPanel('Parent',ch_layout,'Title','Residual');
res_ax = axes('Parent',res_box);

ch_layout.Heights = [-2.5 -1];

button_layout = uix.HBox('Parent',layout);
uix.Empty('Parent',button_layout);
uicontrol(button_layout,'Style','pushbutton','String','Cancel','Callback', @(~,~) close(fh));
save_button = uicontrol(button_layout,'Style','pushbutton','String','Save IRF...','Enable','off','Callback',@save);
button_layout.Widths = [-1 200 200];
layout.Heights = [-1 30];

[analytical_parameters, chi2] = estimate_polarisation_resolved_analytical_irf(t,data,T,fit_ax,res_ax);

save_button.Enable = 'on';

function save(~,~)

    if max(chi2) > 1.3
        h = warndlg({'The quality of fit produced with the estimated IRF is relatively low,',...
            'you might need to directly measure the IRF'},'Warning');
        waitfor(h);
    end

    text = jsonencode(analytical_parameters);

    [file, path] = uiputfile({'*.json', 'JSON file (*.json)'},'Select file name',default_path);

    f = fopen([path file],'w');
    fprintf(f,text);
    fclose(f);
end

end
