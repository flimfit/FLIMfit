function compile_external(v)

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

    distrib_folder = 'X:\Group\Software\Global Analysis External\';

    fid = fopen('GeneratedFiles\version.txt','w');
    fwrite(fid,v);
    fclose(fid);
    
    if is64
        sys = '64';
    else
        sys = '32';
    end

    try
    exe = ['DeployFiles\GlobalProcessing_' sys '.exe'];
    delete(exe);
    end
    
    eval(['deploytool -build GlobalProcessingExternal_' sys '.prj']);
    
    while ~exist(exe,'file')
       pause(0.2);
    end
    
    deploy_folder = ['..\GlobalProcessingStandalone\GlobalProcessing_' v '_' sys];
    
    mkdir(deploy_folder);
    
    copyfile(exe,deploy_folder);
    
    if ~isempty(strfind(computer,'PCWIN'))
        lib_ext = 'dll';
    elseif ~isempty(strfind(computer,'MAC'))
        lib_ext = 'dylib';
    else
        lib_ext = 'so';
    end
    
    copyfile(['DeployFiles\Start_GlobalProcessing_' sys '.exe'],deploy_folder);
    copyfile(['..\GlobalProcessingLibrary\Libraries\FLIMGlobalAnalysis_' sys '.' lib_ext],deploy_folder);

    mkdir([distrib_folder 'GlobalProcessing_' v]);
    copyfile(deploy_folder,[distrib_folder 'GlobalProcessing_' v filesep 'GlobalProcessing_' v '_' computer filesep]);
    
    %{
    chlog_file = [distrib_folder 'Changelog.txt'];
    f = fopen(chlog_file);
    
    l = fgetl(f);
    log = false;
    change = [];
    while ischar(l)
       if strcmp(l,['v' v])
           log = true;
       end
       if log
           change = [change l '\r\n'];
       end
       l = fgetl(f);
    end
    if isempty(change)
        change = ['v' v];
    end
    %}
    
    %{
    cd('..');
    %system('hg addremove');
    system(['hg commit -m "' v ' (' computer ')"']);
    cd('GlobalProcessingFrontEnd');
    %}
    
    try
        rmdir(['GlobalProcessing_' sys]);
    catch e %#ok
    end
    
end