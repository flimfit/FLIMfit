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

    distrib_folder = 'Y:\Group\Software\Global Analysis\';

    fid = fopen(['GeneratedFiles' filesep 'version.txt'],'w');
    fwrite(fid,v);
    fclose(fid);
    
    if is64
        sys = '64';
    else
        sys = '32';
    end

    exe = ['DeployFiles\FLIMfit_' sys '.exe'];
    
    try
    delete(exe);
    end
    
    eval(['deploytool -build FLIMfit_' sys '.prj']);
   
    while ~exist(exe,'file')
       pause(0.2);
    end
   %
    deploy_folder = ['..\FLIMfitStandalone\FLIMfit_' v '_' sys];
    
    mkdir(deploy_folder);
    
    copyfile(exe,deploy_folder);
    
    if ~isempty(strfind(computer,'PCWIN'))
        lib_ext = 'dll';
    elseif ~isempty(strfind(computer,'MAC'))
        lib_ext = 'dylib';
    else
        lib_ext = 'so';
    end
    
    %copyfile(['DeployFiles\GlobalProcessing_' sys '.ctf'],deploy_folder);
    copyfile(['DeployFiles\Start_FLIMfit_' sys '.exe'],deploy_folder);
    copyfile(['..\GlobalProcessingLibrary\Libraries\FLIMGlobalAnalysis_' sys '.' lib_ext],deploy_folder);
    
    if strcmp(sys,'64')
        arch = 'x64';
    else
        arch = 'x86';
    end
    
    system(['"C:\Program Files (x86)\Inno Setup 5\iscc" /dMyAppVersion=' v ' /dMyAppSystem=' sys ' /dMyAppArch=' arch ' "InstallerScript.iss"'])

    
    mkdir([distrib_folder 'FLIMfit_' v]);
    
    new_distrib_folder = [distrib_folder 'FLIMfit_' v filesep 'FLIMfit' v '_' computer filesep];
    copyfile(deploy_folder,new_distrib_folder);

    installer_file_name = ['FLIMfit ' v ' Setup x' sys '.exe'];
    installer_file = ['..\FLIMfitStandalone\Installer\' installer_file_name];
    copyfile(installer_file,[distrib_folder 'FLIMfit_' v filesep installer_file_name]);

   

    
    try
        rmdir(['FLIMfit_' sys]);
    catch e %#ok
    end
    
    
end