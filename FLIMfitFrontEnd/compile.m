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

        [~,v] = system('git describe','-echo');
        v = v(1:end-1);

        fid = fopen(['GeneratedFiles' filesep 'version.txt'],'w');
        fwrite(fid,v);
        fclose(fid);

        if contains(computer,'PCWIN')
            platform = 'WIN';
            lib_ext = '.dll';
            exe_ext = '.exe';
        elseif contains(computer,'MAC')
            platform = 'MAC';
            lib_ext = '.dylib';
            exe_ext = '.app';
        else
            platform = 'LINUX';
            lib_ext = '.so';
            exe_ext = '';
        end

        addpath_global_analysis();
 		generate_segmentation_functions_file();


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
                    if exist(exe,'dir')
                        rmdir(exe,'s');
                    end
            end

            % Build executable
            switch platform
                case 'WIN'
                    mcc -m FLIMfit.m -v -d DeployFiles ...
                        -a Libraries/* ...
                        -a FLIMGlobalAnalysisProto_PCWIN64.m ...
                        -a FLIMGlobalAnalysis_64_thunk_pcwin64.dll ...
                        -a segmentation_funcs.mat ...
                        -a icons.mat ...
                        -a SegmentationFunctions/*  ...
                        -a SegmentationFunctions/Support/* ...
                        -a pdftops.exe ...
                        -a FLIMfit-logo-colour.png ...
                        -a ThirdParty/bfmatlab/* ...
                        -a ThirdParty/omero-matlab/libs/* ...
                        -a ThirdParty/omero-matlab/* ...
                        -a GeneratedFiles/version.txt ...
                        -a 'Toolboxes/GUI Layout Toolbox/layout' ...
                        -a LicenseFiles/*.txt

                case 'MAC'
                    
                    mklroot = getenv('MKLROOT');
                    for lib = {'FLIMGlobalAnalysis_64.dylib', 'FlimReaderMex.mexmaci64'}
                        if ~isempty(mklroot)
                            for mkllib = {'libmkl_intel_lp64', 'libmkl_sequential', 'libmkl_core', 'libmkl_rt'}
                                system(cell2mat(['install_name_tool -change @rpath/' mkllib '.dylib ' mklroot '/lib/' mkllib '.dylib Libraries/' lib]))
                            end
                        end
                        system(cell2mat(['DeployFiles/dylibbundler -of -x Libraries/' lib ' -b  -d Libraries -p @loader_path']));
                    end 

                    mcc -m FLIMfit.m -v -d DeployFiles ...
                        -a Libraries/* ...
                        -a FLIMGlobalAnalysis_64_thunk_maci64.dylib ...
                        -a FLIMGlobalAnalysisProto_MACI64.m  ...
                        -a segmentation_funcs.mat ...
                        -a icons.mat ...
                        -a SegmentationFunctions/* ...
                        -a SegmentationFunctions/Support/*  ...
                        -a pdftops.bin ...
                        -a FLIMfit-logo-colour.png ...
                        -a ThirdParty/bfmatlab/* ...
                        -a ThirdParty/omero-matlab/libs/* ...
                        -a ThirdParty/omero-matlab/* ...
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

                get_file('..\InstallerSupport\gs916w64.exe','http://downloads.flimfit.org/gs/gs916w64.exe')
                
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

                copyfile(['Libraries\FLIMGlobalAnalysis_' sys lib_ext],deploy_folder);

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

                if ~exist('..\FLIMfitLibrary\VisualStudioRedistributablePath.txt', 'file')
                    disp('No VS Redistributable location found.');
                end
                fid = fopen('..\FLIMfitLibrary\VisualStudioRedistributablePath.txt','r');
                redist_file = fgetl(fid);
                redist_file = [strrep(redist_file,'/','\') '\vcredist_x64.exe'];
                fclose(fid);

                root = [cd '\..'];
                cmd = ['"C:\Program Files (x86)\Inno Setup 5\iscc" /dMcrVer="' mcr_v '" /dMatlabVer="' matlab_v ...
                       '" /dAppVersion="' v '" /dInnoAppVersion="' v_inno '" /dRepositoryRoot="' root '" /dVSRedist="' redist_file '" "InstallerScript.iss"'];
                disp(cmd);
                system(cmd);


            case 'MAC'

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
                fid = fopen([deployFiles_folder filesep 'FLIMfit_platypus.sh'],'r');
                script = fread(fid);
                fclose(fid);
                script = strrep(script,'[MCR_VERSION_MAJOR]',num2str(major));
                script = strrep(script,'[MCR_VERSION_MINOR]',num2str(minor));
                script = strrep(script,'[MATLAB_VERSION]',version('-release'));
                
                fid = fopen([deployFiles_folder filesep 'FLIMfit_platypus_versioned.sh'],'w');
                fwrite(fid,script);
                fclose(fid);

                cmd = ['/usr/local/bin/platypus -y -P FLIMfit.platypus -a "' package_name '" -V ' v ' ' deploy_folder '/' package_name];

                final_folder = ['..' filesep 'FLIMfitStandalone' filesep 'BuiltApps' filesep];
                mkdir(final_folder);

                pause(3)
                system(cmd);
                pause(3)
                
                final_file = [final_folder package_name '.app'];
                movefile([deploy_folder '/FLIMfit.app'], final_file);
                
                % sign code - need to have certificate installed
                disp('Signing executable...')
                [~,response] = system(['codesign -s P6MM899VL9 "' final_file '"/']);
                disp(response);
                
                cd('Libraries')
                zip(['flimfit_libraries_maci64_' v '.zip'],{'*.dylib','*.mexmaci64'})
                cd('..')
        end
    end
    
end


