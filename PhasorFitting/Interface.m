function Interface()

    fh = figure('ToolBar','none','Name','Phasor Fitting','NumberTitle','off');
    
    layout = uiextras.HBox('Parent',fh);
    
    blayout = uiextras.VBox('Parent', layout, 'Spacing', 10,'Padding', 20);
    ax = axes('Parent', layout);
    set(layout, 'Sizes', [200 -1]);
    
    AddButton('Get Reference', @() GetReference(ax));
    AddButton('Fit IRF', @() RunFitIRF(ax)); 
    AddButton('Process Folder', @ProcessFLIMFolder);
    
    sizes = 50 * ones(1,length(blayout.Children));
    uiextras.Empty('Parent', blayout);
    set(blayout, 'Sizes', [sizes -1]);
    
    function AddButton(name, callback)
        uicontrol('Style','PushButton','String',name,'Parent',blayout,'Callback',@(~,~) callback());
    end

end