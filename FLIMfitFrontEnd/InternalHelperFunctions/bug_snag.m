function bug_snag(error)

    if ~isdeployed
        return
    end

    % Get version
    fid = fopen('GeneratedFiles/version.txt');
    flimfit_ver = fgetl(fid);
    fclose(fid);

    % Get user ID
    if ~ispref('FLIMfit','UID')
        uid = dec2hex(randi(1e10));
        setpref('FLIMfit','UID',uid);
    end
    uid = getpref('FLIMfit','UID');

    report.apiKey = '621724d764d2cf3ebbca01f5c978e686';
    report.notifier.name = 'bugsnag-matlab';
    report.notifier.version = '0.1.0';
    report.notifier.url = 'http://www.github.com/seanwarren/bugsnag-matlab';

    event.payloadVersion = '2';
    event.exceptions{1}.errorClass = error.identifier;
    event.exceptions{1}.message = error.message;    
    
    for i=1:length(error.stack)
        s = error.stack(i);
        [~,method] = fileparts(s.file);
        event.exceptions{1}.stacktrace{i} = ...
            struct('file',s.file,'lineNumber',s.line,'method',method);
    end
        
    event.severity = 'error';
    event.user.id = uid;
    
    event.app.version = flimfit_ver;
    
    if isdeployed
        event.app.type = 'compiled';
    else
        event.app.type = 'testing';
    end
        
    matlab_ver = ver('MATLAB');
    matlab_ver = matlab_ver.Release;
    
    event.device.osVersion = [computer ' ' matlab_ver];
    
    report.events{1} = event;
        
    options = weboptions('ContentType','auto','MediaType','application/json');
    webwrite('https://notify.bugsnag.com',report,options);
    
end


