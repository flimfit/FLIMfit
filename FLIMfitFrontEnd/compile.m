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
        server = '\\ph-nas-02.ph.ic.ac.uk\';
        
        
        % setup compiler on windows
        if strcmp(computer,'PCWIN64')
            mex_setup_dir = [matlabroot '\bin\win64'];
        else
            mex_setup_dir = [matlabroot '\bin\win32'];
        end
        f = [mex_setup_dir '\mexopts\msvc110opts.bat'];
        %copyfile(f,'mexopts.bat');
        
        
    elseif ~isempty(strfind(computer,'MAC'))
        platform = 'MAC';
        lib_ext = '.dylib';
        exe_ext = '.app';
        server = '/Volumes/';
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

    if is64
        sys = '64';
    else
        sys = '32';
    end    
    
    % Build compiled Matlab project
    %------------------------------------------------
    exe = ['DeployFiles' filesep 'FLIMfit_' computer exe_ext];

    if(true)

        % Try and delete executable if it already exists
        %------------------------------------------------


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

        eval(['deploytool -build FLIMfit_' computer '.prj']);

        while ~exist(exe,'file')
           pause(3);
        end
    end
   
    % Create deployment folder in FLIMfitStandalone
    %------------------------------------------------
    deploy_folder = ['..' filesep 'FLIMfitStandalone' filesep 'FLIMfit_' v '_' computer]
    mkdir(deploy_folder);
    
   

    switch platform
        case 'WIN'
            % Make installer using Inno Setup

            copyfile(exe,deploy_folder);
            
            f = fopen([deploy_folder '\Start_FLIMfit_' sys '.bat'],'w');
            fprintf(f,'@echo off\r\necho Starting FLIMfit...\r\n');
            fprintf(f,'if "%%LOCALAPPDATA%%"=="" (set APPDATADIR=%%APPDATA%%) else (set APPDATADIR=%%LOCALAPPDATA%%)\r\n');
            fprintf(f,['set MCR_CACHE_ROOT=%%APPDATADIR%%\\FLIMfit_' v '_' computer '_MCR_cache\r\n']);
            fprintf(f,'if not exist "%%MCR_CACHE_ROOT%%" echo Decompressing files for first run, please wait this may take a few minutes\r\n');
            fprintf(f,'if not exist "%%MCR_CACHE_ROOT%%" mkdir "%%MCR_CACHE_ROOT%%"\r\n');
            fprintf(f,['FLIMfit_' computer '.exe \r\n pause']);
            fclose(f);
            
            copyfile(['..\FLIMfitLibrary\Libraries\FLIMGlobalAnalysis_' sys lib_ext],deploy_folder);

            if strcmp(sys,'64')
                arch = 'x64';
            else
                arch = 'x86';
            end

            root = [cd '\..'];
            cmd = ['"C:\Program Files (x86)\Inno Setup 5\iscc" /dMyAppVersion="' v '" /dMyAppSystem=' sys ' /dMyAppArch=' arch ' /dRepositoryRoot="' root '" "InstallerScript.iss"']
            system(cmd);

            installer_file_name = ['FLIMfit ' v ' Setup ' arch '.exe'];
            installer_file = ['..\FLIMfitStandalone\Installer\' installer_file_name];
            
            
             % Try and copy files to Imperial server
            %------------------------------------------------
            distrib_folder = [server 'fogim_datastore' filesep 'Group' filesep 'Software' filesep 'Global Analysis' filesep];


            mkdir([distrib_folder 'FLIMfit_' v]);

            new_distrib_folder = [distrib_folder 'FLIMfit_' v filesep 'FLIMfit_' v '_' computer filesep];
            copyfile(deploy_folder,new_distrib_folder);   


            if strcmp(platform,'WIN')
                copyfile(installer_file,[distrib_folder 'FLIMfit_' v filesep installer_file_name]);
            end
            
            copyfile('..\changelog.md',[distrib_folder 'Changelog.txt'])

            

        case 'MAC'
           
             pause(3);
             
             
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
            % Macports GCC 4.7 [FLIMfit_GCC47MP.platypus]
            cmd = ['/usr/local/bin/platypus -y -P FLIMfit_GCC47HB.platypus -a "' package_name '" -V ' v ' ' deploy_folder '/' package_name];
            
            
            system(cmd);
            movefile([deploy_folder '/FLIMfit.app'], [deploy_folder '/' package_name '.app']);
            pause(3)
            
            
    end
    

   
    
%    try
%        rmdir(['FLIMfit_' sys]);
%    catch e %#ok
%    end
    
    
end