function compile(v)

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

    disp( 'Starting Matlab compilation.' );

    if nargin >= 1
        fid = fopen(['GeneratedFiles' filesep 'version.txt'],'w');
        fwrite(fid,v);
        fclose(fid);
    else
        fid = fopen(['GeneratedFiles' filesep 'version.txt'],'r');
        v = fgetl(fid);
        fclose(fid);
    end
    
    if ~isempty(strfind(computer,'PCWIN'))
        platform = 'WIN';
        lib_ext = '.dll';
        exe_ext = '.exe';
    elseif ~isempty(strfind(computer,'MAC'))
        platform = 'MAC';
        lib_ext = '.dylib';
        exe_ext = '.app';
    else
        platform = 'LINUX';
        lib_ext = '.so';
        exe_ext = '';
    end
        
    addpath_global_analysis();
        
    
    % Make sure we have included the DLL
    dll_interface = flim_dll_interface();
    dll_interface.unload_global_library();
    dll_interface.load_global_library();

    sys = '64'; % deprecate support for 32 bit
    
    % Build compiled Matlab project
    %------------------------------------------------
    exe = ['DeployFiles' filesep 'FLIMfit' exe_ext];

    if(true)

        % Try and delete executable if it already exists
        switch platform
            case 'WIN'
                if exist(exe,'file')
                    delete(exe);
                end
            case 'MAC'
                if isdir(exe)
                    rmdir(exe,'s');
                end
        end
        
        % Build executable
        switch platform
            case 'WIN'
                mcc -m FLIMfit.m -v -d DeployFiles ...
                    -a FLIMGlobalAnalysisProto_PCWIN64.m ...
                    -a FLIMGlobalAnalysis_64_thunk_pcwin64.dll ...
                    -a ../FLIMfitLibrary/Libraries/FLIMreaderMex.mexw64 ...
                    -a segmentation_funcs.mat ...
                    -a icons.mat ...
                    -a SegmentationFunctions/*  ...
                    -a SegmentationFunctions/Support/* ...
                    -a pdftops.exe ...
                    -a FLIMfit-logo-colour.png ...
                    -a BFMatlab/*.jar ...
                    -a OMEROMatlab/libs/*.jar ...
                    -a OMEuiUtils/*.jar ...
                    -a OMEROMatlab/*.config ...
                    -a GeneratedFiles/version.txt ...
                    -a 'Toolboxes/GUI Layout Toolbox/layout' ...
                    -a LicenseFiles/*.txt
                
            case 'MAC'
                mcc -m FLIMfit.m -v -d DeployFiles ...
                    -a ../FLIMfitLibrary/Libraries/FLIMGlobalAnalysis_64.dylib ...
                    -a FLIMGlobalAnalysis_64_thunk_maci64.dylib ...
                    -a FLIMGlobalAnalysisProto_MACI64.m  ...
                    -a ../FLIMfitLibrary/Libraries/FLIMreaderMex.maci64 ...
                    -a segmentation_funcs.mat ...
                    -a icons.mat ...
                    -a SegmentationFunctions/* ...
                    -a SegmentationFunctions/Support/*  ...
                    -a pdftops.bin ...
                    -a FLIMfit-logo-colour.png ...
                    -a BFMatlab/*.jar ...
                    -a OMEROMatlab/libs/*.jar ...
                    -a OMEuiUtils/*.jar ...
                    -a OMEROMatlab/*.config ...
                    -a GeneratedFiles/version.txt ...
                    -a 'Toolboxes/GUI Layout Toolbox/layout' ...
                    -a LicenseFiles/*.txt
        end

        while ~exist(exe,'file')
            pause(3);
        end
        
    end
    
   
    % Create deployment folder in FLIMfitStandalone
    %------------------------------------------------
    deploy_folder = ['..' filesep 'FLIMfitStandalone' filesep 'FLIMfit_' v]

    disp( ['creating folder at  ' deploy_folder ] );
    mkdir(deploy_folder);
    disp( 'created folder successfully! ' );
    
   

    switch platform
        case 'WIN'
            % Make installer using Inno Setup

            copyfile(exe,deploy_folder);
            
            f = fopen([deploy_folder '\Start_FLIMfit.bat'],'w');
            fprintf(f,'@echo off\r\necho Starting FLIMfit...\r\n');
            fprintf(f,'if "%%LOCALAPPDATA%%"=="" (set APPDATADIR=%%APPDATA%%) else (set APPDATADIR=%%LOCALAPPDATA%%)\r\n');
            % fprintf(f,'set MCR_CACHE_VERBOSE=1');
            fprintf(f,['set MCR_CACHE_ROOT=%%APPDATADIR%%\\FLIMfit_' v '_' computer '_MCR_cache\r\n']);
            fprintf(f,'if not exist "%%MCR_CACHE_ROOT%%" echo Decompressing files for first run, please wait this may take a few minutes\r\n');
            fprintf(f,'if not exist "%%MCR_CACHE_ROOT%%" mkdir "%%MCR_CACHE_ROOT%%"\r\n');
            fprintf(f,'FLIMfit.exe \r\n pause');
            fclose(f);
            
            copyfile(['..\FLIMfitLibrary\Libraries\FLIMGlobalAnalysis_' sys lib_ext],deploy_folder);

            matlab_v = version('-release');
            [major, minor] = mcrversion;
            mcr_v = [num2str(major) '.' num2str(minor)];
            
            if ~exist('..\FLIMfitLibrary\VisualStudioRedistributablePath.txt', 'file')
                disp('No VS Redistributable location found. Please run Configure_WIN.bat in repository root');
            end
            fid = fopen('..\FLIMfitLibrary\VisualStudioRedistributablePath.txt','r');
            redist_file = fgetl(fid);
            fclose(fid);
            
            root = [cd '\..'];
            cmd = ['"C:\Program Files (x86)\Inno Setup 5\iscc" /dMcrVer="' mcr_v '" /dMatlabVer="' matlab_v ...
                   '" /dMyAppVersion="' v '" /dRepositoryRoot="' root '" /dVSRedist="' redist_file '" "InstallerScript.iss"'];
            disp(cmd);
            system(cmd);
                                                                                                                                                                                                                         
                                                                                                                                                                                                      
        case 'MAC'
           
            % wait for the build to complete
            MacOS_folder = [ './' exe filesep 'Contents' filesep 'MacOS']
            filename = [ MacOS_folder '/FLIMfit']
            while ~exist(filename,'file')
                pause(3);
            end
             
             
            % change icon by overwriting matlab membrane.icns
            deployFiles_folder = ['.' filesep 'DeployFiles']
            resource_folder = [ './' exe filesep 'Contents' filesep 'Resources']
            
            
 
            
            filename = [resource_folder '/membrane.icns']
            if exist([resource_folder '/membrane.icns'], 'file') == 2
                    delete([resource_folder '/membrane.icns'])
                    pause(2);
            end
            
           
            disp( ['copying ' deployFiles_folder '/microscopeGreen.icns' ' to ' resource_folder '/membrane.icns' ] );
            
            copyfile( [deployFiles_folder '/microscopeGreen.icns'], [resource_folder '/membrane.icns' ],'f');
           
            pause(1);
            
            % Package app with platypus
            package_name = ['FLIMfit ' v];
            
            % NB The platypus profile file FLIMfit_????.platypus used in the following line will
            % determine which files are included  in the final .app 
            % Please use an appropriate configuration for your build
            % environment 
            % examples are included for:
            % Homebrew GCC 4.7 [FLIMfit_GCC47HB.platypus]
            disp( 'NB Currently uses GCC as configured at University of  Dundee!! ');
            disp ('If building elewhere use the appropriate .platypus file!');
            
            cmd = ['/usr/local/bin/platypus -y -P FLIMfit_GCC49HB.platypus -a "' package_name '" -V ' v ' ' deploy_folder '/' package_name]
            
           
            pause(3)
            system(cmd);
            pause(3)
            movefile([deploy_folder '/FLIMfit.app'], [deploy_folder '/' package_name '.app']);
            
            
            
    end
    
    
end


