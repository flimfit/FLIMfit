function compile(exit_on_error)

% Copyright (C) 2013 Imperial College London.
% All rights reserved.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%
% This software tool was developed with support from the UK 
% Engineering and Physical Sciences Council 
% through  a studentship from the Institute of Chemical Biology 
% and The Wellcome Trust through a grant entitled 
% "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

% Author : Sean Warren

    if nargin < 1
        exit_on_error = false;
    end
    
    if exit_on_error    
        try
           run 
        catch e
           disp('..')
           disp(getReport(e,'extended'));
           exit(1)
        end
    else
        run
    end

    function run
        
        disp( 'Starting Matlab compilation.' );

        addpath_global_analysis();
 		generate_segmentation_functions_file();

        % Write version file
        v = get_git_version();
        fid = fopen(['GeneratedFiles' filesep 'version.txt'],'w');
        fwrite(fid,v);
        fclose(fid);
        
        % Delete existing build and setup platform 
        if contains(computer,'PCWIN')
            platform = 'pcwin64';
            exe = ['DeployFiles' filesep 'FLIMfit.exe'];
            pdftops = 'pdftops.exe';

            if exist(exe,'file')
                delete(exe);
            end
            
        elseif contains(computer,'MAC')
            platform = 'maci64';
            exe = ['DeployFiles' filesep 'FLIMfit.app'];
            pdftops = 'pdftops.bin';

            if exist(exe,'dir')
                rmdir(exe,'s');
            end
        end

        % Manually fix Qt references on mac
        if ismac
            for lib = {'FLIMfitMex', 'FlimReader'}
                system(cell2mat(['DeployFiles/dylibbundler -of -x Libraries/' lib '.mexmaci64 -b  -d Libraries -p @loader_path']));
            end 
        end
        
        % Build compiled Matlab project
        additional_folders = {...
            'Libraries' ...
            'segmentation_funcs.mat' ...
            'icons.mat' ...
            'SegmentationFunctions' ...
            'FLIMfit-logo-colour.png' ...
            ['ThirdParty' filesep 'pdftops' filesep pdftops] ...
            ['ThirdParty' filesep 'bfmatlab'] ...
            ['ThirdParty' filesep 'omero-matlab'] ...
            ['GeneratedFiles' filesep 'version.txt'] ...
            ['matlab-ui-common' filesep 'layout'] ...
            ['LicenseFiles' filesep '*.txt']};

        args = {'-m','FLIMfit.m', '-v', '-d', 'DeployFiles'};
        for i=1:length(additional_folders)
            args = [args {'-a' additional_folders{i}}];
        end
        mcc(args{:});

        while ~exist(exe,'file')
            pause(3);
        end
        
        % Create deployment folder in FLIMfitStandalone
        deploy_folder = ['..' filesep 'FLIMfitStandalone' filesep 'FLIMfit_' v];
        disp( ['Creating folder at  ' deploy_folder ] );
        mkdir(deploy_folder);

        % Build installer
        if ispc

            % Make installer using Inno Setup
            get_file('..\InstallerSupport\gs916w64.exe','http://downloads.flimfit.org/gs/gs916w64.exe')

            copyfile(exe,deploy_folder);

            f = fopen([deploy_folder '\Start_FLIMfit.bat'],'w');
            fprintf(f,'@echo off\r\necho Starting FLIMfit...\r\n');
            fprintf(f,'if "%%LOCALAPPDATA%%"=="" (set APPDATADIR=%%APPDATA%%) else (set APPDATADIR=%%LOCALAPPDATA%%)\r\n');
            fprintf(f,['set MCR_CACHE_ROOT=%%APPDATADIR%%\\FLIMfit_' v '_' computer '_MCR_cache\r\n']);
            fprintf(f,'if not exist "%%MCR_CACHE_ROOT%%" echo Decompressing files for first run, please wait this may take a few minutes\r\n');
            fprintf(f,'if not exist "%%MCR_CACHE_ROOT%%" mkdir "%%MCR_CACHE_ROOT%%"\r\n');
            fprintf(f,'FLIMfit.exe \r\n pause');
            fclose(f);

            matlab_v = version('-release');
            [major, minor] = mcrversion;
            mcr_v = [num2str(major) '.' num2str(minor)];

            % Make a version number that Inno setup likes
            v_tokens = regexp(v,'(\d+\.\d+\.\d+)(?:-*RC){0,1}-(\d+)-([a-z0-9]+)','tokens');
            if ~isempty(v_tokens)
                t = v_tokens{1};
                v_inno = [t{1} '.' t{2}];
            else
                v_inno = v;
            end
            v_inno = regexprep(v_inno,'([^\d\.]+)','');

            root = [cd '\..'];
            cmd = ['"C:\Program Files (x86)\Inno Setup 5\iscc" /dMcrVer="' mcr_v '" /dMatlabVer="' matlab_v ...
                   '" /dAppVersion="' v '" /dInnoAppVersion="' v_inno '" /dRepositoryRoot="' root '" InstallerScript.iss"'];
            disp(cmd);
            system(cmd);

        elseif ismac

            % wait for the build to complete
            MacOS_folder = [ './' exe filesep 'Contents' filesep 'MacOS'];
            filename = [ MacOS_folder '/FLIMfit'];
            while ~exist(filename,'file')
                pause(3);
            end

            % change icon by overwriting matlab membrane.icns
            deployFiles_folder = ['.' filesep 'DeployFiles'];
            resource_folder = [ './' exe filesep 'Contents' filesep 'Resources'];

            if exist([resource_folder '/membrane.icns'], 'file') == 2
                delete([resource_folder '/membrane.icns'])
                pause(2);
            end

            disp( ['copying ' deployFiles_folder '/FLIMfit-icon-grey.icns' ' to ' resource_folder '/membrane.icns' ] );
            copyfile( [deployFiles_folder '/FLIMfit-icon-grey.icns'], [resource_folder '/membrane.icns' ],'f');

            pause(1);

            % Package app with platypus
            package_name = ['FLIMfit ' v];

            [major,minor] = mcrversion;

            % Setup platypus script
            script = fileread([deployFiles_folder filesep 'FLIMfit_platypus.sh']);
            script = strrep(script,'[MCR_VERSION_MAJOR]',num2str(major));
            script = strrep(script,'[MCR_VERSION_MINOR]',num2str(minor));
            script = strrep(script,'[MATLAB_VERSION]',version('-release'));

            fid = fopen([deployFiles_folder filesep 'FLIMfit_platypus_versioned.sh'],'w');
            fwrite(fid,script);
            fclose(fid);

            cmd = ['/usr/local/bin/platypus -y -P DeployFiles/FLIMfit.platypus -a "' package_name '" -V ' v ' ' deploy_folder '/' package_name];

            final_folder = ['..' filesep 'FLIMfitStandalone' filesep 'BuiltApps' filesep];
            mkdir(final_folder);

            pause(3)
            system(cmd);
            pause(3)

            final_file = [final_folder package_name '.app'];

            if exist(final_file,'dir')
               rmdir([final_file '/'],'s')
            end

            movefile([deploy_folder '/FLIMfit.app'], final_file, 'f');

            % sign code - need to have certificate installed
            disp('Signing executable...')
            [~,response] = system(['codesign -s P6MM899VL9 "' final_file '"/']);
            disp(response);
        end
        
        % Zip up libraries
        zip(['flimfit_libraries_' platform '_' v '.zip'],['Libraries' filesep '*'])
        
    end
    
end


