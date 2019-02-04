function check_prefs(obj)
    
    % This function deletes the preferences if we're running on a different
    % computer to when they were set - i.e. if we're deployed

    if strcmp(computer,'MACI64')
        [status, hostname] = unix('scutil --get ComputerName');

    else
        % NB Is this reliable on a PC? May only work if user has set this
        % variable
        hostname = getenv('COMPUTERNAME');
    end
    
    try
    
        pref_hostname = getpref('GlobalAnalysisFrontEnd','hostname');
        setpref('GlobalAnalysisFrontEnd','hostname',hostname)
        
        if (~strcmp(pref_hostname,hostname))
           
            if ispref('GlobalAnalysisFrontEnd','DefaultFolder')
                rmpref('GlobalAnalysisFrontEnd','DefaultFolder');
            end
            if ispref('GlobalAnalysisFrontEnd','RecentData')
                rmpref('GlobalAnalysisFrontEnd','RecentData');
            end
            if ispref('GlobalAnalysisFrontEnd','RecentIRF')
                rmpref('GlobalAnalysisFrontEnd','RecentIRF');
            end
            if ispref('GlobalAnalysisFrontEnd','RecentDefaultPath')
                rmpref('GlobalAnalysisFrontEnd','RecentDefaultPath');
            end
            if ispref('GlobalAnalysisFrontEnd','OMEROlogin')
                rmpref('GlobalAnalysisFrontEnd','OMEROlogin');
            end
            if ispref('GlobalAnalysisFrontEnd','NeverOMERO')
                rmpref('GlobalAnalysisFrontEnd','NeverOMERO');
            end
           
           
            
            
        end
    
    catch
        
        addpref('GlobalAnalysisFrontEnd','hostname',hostname)
        
    end
end