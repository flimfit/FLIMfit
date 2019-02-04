function close_request_fcn(src,~)

    diagnostics('program','end');

    h = guidata(src);
    client = h.omero_logon_manager.client;

    delete(h.data_series_controller.data_series)

    if ~isempty(client)                
        disp('Closing OMERO session');
        client.closeSession();
        h.omero_logon_manager.session = [];
        h.omero_logon_manager.client = [];
    end


    % Make sure we clean up all the left over classes
    names = fieldnames(h);

    for i=1:length(names)
        % Check the field is actually a handle and isn't the window
        % which we need to close right at the end
        if ~strcmp(names{i},'window') && all(ishandle(h.(names{i})))
            delete(h.(names{i}));
        end
    end

    % Get rid of global figure created by plotboxpos
    global f_temp
    if ~isempty(f_temp) && ishandle(f_temp)
        close(f_temp)
        f_temp = [];
    end

    % Finally actually close window
    delete(h.window);

end