function diagnostics
    try
        fid = fopen('GeneratedFiles/version.txt');
        ver = fgetl(fid);
        fclose(fid);

        if true || ~ispref('FLIMfit','UID')
            uid = dec2hex(randi(1e10));
            setpref('FLIMfit','UID',uid);
        end
        uid = getpref('FLIMfit','UID');
        event_category = 'program';
        event_action = 'start';
        event_label = 'start';
        data = ['v=1&t=event&tid=UA-72259304-2&cid=' uid '&ec=' event_category '&ea=' event_action '&el=' event_label];
        data = [data 'an=FLIMfit&av=' ver];
        webwrite('http://www.google-analytics.com/collect',data);
    catch e
        disp('Diagnostics error:')
        disp(e.message);
    end
        