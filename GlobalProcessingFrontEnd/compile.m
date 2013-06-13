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


    addpath_global_analysis();

    fid = fopen(['GeneratedFiles' filesep 'version.txt'],'w');
    fwrite(fid,v);
    fclose(fid);
    
    if ~isempty(strfind(computer,'PCWIN'))
        platform = 'WIN';
        lib_ext = '.dll';
        exe_ext = '.exe';
        server = '\\ph-nas-02.ph.ic.ac.uk\';
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
    
    
    if is64
        sys = '64';
    else
        sys = '32';
    end

    % Try and delete executable if it already exists
    %------------------------------------------------
   
    exe = ['DeployFiles' filesep 'FLIMfit_' computer exe_ext];
    
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
    
    % Build compiled Matlab project
    %------------------------------------------------
    
    eval(['deploytool -build FLIMfit_' computer '.prj']);
   
    while ~exist(exe,'file')
       pause(0.2);
    end
   
   
    % Create deployment folder in FLIMfitStandalone
    %------------------------------------------------
    deploy_folder = ['..' filesep 'FLIMfitStandalone' filesep 'FLIMfit_' v '_' computer];
    mkdir(deploy_folder);
    
    

    switch platform
        case 'WIN'
            % Make installer using Inno Setup

            copyfile(exe,deploy_folder);
            copyfile(['DeployFiles\Start_FLIMfit_' sys '.exe'],deploy_folder);
            copyfile(['..\GlobalProcessingLibrary\Libraries\FLIMGlobalAnalysis_' sys lib_ext],deploy_folder);

            if strcmp(sys,'64')
                arch = 'x64';
            else
                arch = 'x86';
            end

            system(['"C:\Program Files (x86)\Inno Setup 5\iscc" /dMyAppVersion="' v '" /dMyAppSystem=' sys ' /dMyAppArch=' arch ' "InstallerScript.iss"'])

            installer_file_name = ['FLIMfit ' v ' Setup x' sys '.exe'];
            installer_file = ['..\FLIMfitStandalone\Installer\' installer_file_name];

        case 'MAC'
            % Package app with platypus
            
            package_name = ['FLIMFit ' v];
            cmd = ['/usr/local/bin/platypus -y -P FLIMfit.platypus -a "' package_name '" -V ' v ' ' deploy_folder '/' package_name];
            system(cmd)
            movefile([deploy_folder '/FLIMfit.app'], [deploy_folder '/' package_name '.app']);
    end
    

    % Try and copy files to Imperial server
    %------------------------------------------------
    distrib_folder = [server 'fogim_datastore' filesep 'Group' filesep 'Software' filesep 'Global Analysis' filesep];

       
    mkdir([distrib_folder 'FLIMfit_' v]);
    
    new_distrib_folder = [distrib_folder 'FLIMfit_' v filesep 'FLIMfit_' v '_' computer filesep];
    copyfile(deploy_folder,new_distrib_folder);   
    
    if strcmp(platform,'WIN')
        copyfile(installer_file,[distrib_folder 'FLIMfit_' v filesep installer_file_name]);
    end
    
    
%    try
%        rmdir(['FLIMfit_' sys]);
%    catch e %#ok
%    end
    
    
end