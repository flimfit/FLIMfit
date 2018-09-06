function check_version(quiet)

    if nargin < 1
        quiet = false;
    end

    try
        url = 'https://www.flimfit.org/current-version.txt';
        options=weboptions; 
        options.CertificateFilename=(''); 
        new_version = webread(url,options);
        [new_version, new_version_str] = process_version(new_version);
        
        if quiet && ispref('GlobalAnalysisFrontEnd','IgnoreNewVersion')
            ignore_version = getpref('GlobalAnalysisFrontEnd','IgnoreNewVersion');
            if strcmp(ignore_version,new_version_str)
                return
            end
        end
        
        fid = fopen('GeneratedFiles/version.txt');
        current_version = fgetl(fid);
        fclose(fid);
        
        current_version = process_version(current_version);

        if ~isempty(new_version) && ~isempty(current_version)
           n = min(length(new_version), length(current_version));

           new_available = false;
           for i=1:n
               if new_version(i) > current_version(i)
                   new_available = true;
               elseif new_version(i) < current_version(i)
                   break;
               end
           end

           if new_available

               button = questdlg(['A new version of FLIMfit (' new_version_str ') is available, would you like to download it now?'],'New version available','Yes','Not Now','Ignore for this version','Yes'); 
               
               switch button,
                   case 'Yes'
                       web('http://flimfit.org/downloads/latest/','-browser');
                   case 'Ignore for this version'
                       setpref('GlobalAnalysisFrontEnd','IgnoreNewVersion',new_version_str);
               end
                       
                   

           else
               
               if (~quiet)
                   helpdlg('The current version is up to date');
               end
               
              disp('Current version is up to date'); 
           end

        end
        
    catch e
        disp('New version check failed');
        disp(e.message); 
        return
    end
    
    
    function [v,m] = process_version(ver_string)
        [v,m] = regexp(ver_string,'(\d+)\.(\d+)\.(\d+)','tokens','match');
        if ~isempty(v)
            v = cellfun(@str2num,v{1});
            m = m{1};
        else
            v = [];
        end
    end
end