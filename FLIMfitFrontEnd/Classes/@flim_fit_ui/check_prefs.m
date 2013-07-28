function check_prefs(obj)
    
    % This function deletes the preferences if we're running on a different
    % computer to when they were set - i.e. if we're deployed

    hostname = getenv('COMPUTERNAME');
    
    try
    
        pref_hostname = getpref('GlobalAnalysisFrontEnd','hostname');
        setpref('GlobalAnalysisFrontEnd','hostname',hostname)
        
        if (~strcmp(pref_hostname,hostname))
           
            rmpref('GlobalAnalysisFrontEnd','DefaultFolder');
            rmpref('GlobalAnalysisFrontEnd','RecentData');
            rmpref('GlobalAnalysisFrontEnd','RecentIRF');
            rmpref('GlobalAnalysisFrontEnd','RecentDefaultPath');
            rmpref('GlobalAnalysisFrontEnd','OMEROlogin');
            
        end
    
    catch
        
        addpref('GlobalAnalysisFrontEnd','hostname',hostname)
        
    end
end