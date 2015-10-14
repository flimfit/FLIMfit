%> @ingroup UserInterfaceControllers
classdef flim_omero_data_manager < handle 
    
    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the
    % This program is free software; you can redistribute it  License, or
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

   
    
    properties(SetObservable = true)
        
        omero_logon_filename = 'omero_logon.xml';        
        logon;
        client;     
        session;    
        dataset;    
        project;    
        plate; 
        screen;        
        %
        selected_channel; % need to keep this for results uploading to Omero...
        userid;       

    end
        
    methods
        
        function obj = flim_omero_data_manager(varargin)            
            handles = args2struct(varargin);
            assign_handles(obj,handles);
            
        end
                                        
        function delete(obj)
        end
                                
        %------------------------------------------------------------------        
        function Load_IRF_annot(obj,data_series,parent)
            
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Please choose IRF file');
            %
            if isempty(str)
                return;
            elseif -1 == str
                % try to look for annotations of data_series' first image..                
                if ~isempty(data_series.image_ids)
                    myimages = getImages(obj.session,data_series.image_ids(1));
                    image = myimages(1);
                    [str, fname] = select_Annotation(obj.session,obj.userid,image,'Choose image(1) IRF');
                end
            end;       
            %
            if isempty(str)                
                return;
            elseif -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            end            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');  
            
            [path,name,ext] = fileparts_inc_OME(fname);
            
            % NB marshal-object is overloaded in OMERO_data_series &
            % load_irf uses marshal_object for .xml files so simply call
            % directly
            if strcmp(ext,'.xml') 
                data_series.load_irf(fname);
                return;
            end;
            
            
            if strcmp(ext,'.sdt')
                fwrite(fid,typecast(str,'uint16'),'uint16');
            else                
                fwrite(fid,str,'*uint8');
            end
            
            fclose(fid);
            
           
            %try
                data_series.load_irf(full_temp_file_name);
            %catch err
            %     [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            %end
            %
            delete(full_temp_file_name); %??
        end            
                         
        
       
        %------------------------------------------------------------------
        function Import_Fitting_Settings(obj,fitting_params_controller, parent)
                     
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Choose fitting settings file');
            %
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');    
                fwrite(fid,str,'*uint8');
            fclose(fid);
            %
            try
                fitting_params_controller.load_fitting_params(full_temp_file_name); 
                delete(full_temp_file_name); 
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end;
        end            
                
        %------------------------------------------------------------------                
        function Omero_logon(obj,~) 
            
            settings = [];
            
            % look in FLIMfit/dev for logon file
            folder = getapplicationdatadir('FLIMfit',true,true);
            subfolder = [folder filesep 'Dev']; 
            if exist(subfolder,'dir')
                logon_filename = [ subfolder filesep obj.omero_logon_filename ];
                if exist(logon_filename,'file') 
                    [ settings, ~ ] = xml_read (logon_filename);    
                    obj.logon = settings.logon;
                end
                
            end
            
            keeptrying = true;
           
            while keeptrying 
                
            if ~ispref('GlobalAnalysisFrontEnd','OMEROlogin')
                neverTriedLog = true;       % set flag if the OMERO dialog login has never been called on this machine
            else
                neverTriedLog = false;
            end
                
            
            % if no logon file then user must login
            if isempty(settings)
                obj.logon = OMERO_logon();
            end
                                               
           if isempty(obj.logon{4})
               if neverTriedLog == true
                   ret_string = questdlg('Respond "Yes" ONLY if you intend NEVER to use FLIMfit with OMERO on this machine!');
                   if strcmp(ret_string,'Yes')
                        addpref('GlobalAnalysisFrontEnd','NeverOMERO','On');
                   end
               end
               return
           end
            
                keeptrying = false;     % only try again in the event of failure to logon
                
                try 
                    port = obj.logon{2};
                    if ischar(port), port = str2num(port); end;
                    obj.client = loadOmero(obj.logon{1},port);                                    
                    obj.session = obj.client.createSession(obj.logon{3},obj.logon{4});
                catch err
                    display(err.message);
                    obj.client = [];
                    obj.session = [];
                    % Construct a questdlg with three options
                    choice = questdlg('OMERO logon failed!', ...
                    'Logon Failure!', ...
                    'Try again to logon','Run FLIMfit in non-OMERO mode','Launch FLIMfit in non-OMERO mode');
                    % Handle response
                    switch choice
                        case 'Try again to logon'
                            keeptrying = true;                                                  
                        case 'Run FLIMfit in non-OMERO mode'
                            % no action keeptrying is already false                       
                    end    % end switch           
                end   % end catch
                if ~isempty(obj.session)
                    obj.client.enableKeepAlive(60); % Calls session.keepAlive() every 60 seconds
                    obj.userid = obj.session.getAdminService().getEventContext().userId;                    
                end
            end     % end while                        
            
        end
       %------------------------------------------------------------------        
       function Omero_logon_forced(obj,~) 
                        
            keeptrying = true;
           
            while keeptrying 
            
            obj.logon = OMERO_logon();
                                    
           if isempty(obj.logon)
               return
           end
            
                keeptrying = false;     % only try again in the event of failure to logon
          
                try 
                    port = obj.logon{2};
                    if ischar(port), port = str2num(port); end;
                    obj.client = loadOmero(obj.logon{1},port);                                    
                    obj.session = obj.client.createSession(obj.logon{3},obj.logon{4});
                catch err
                    display(err.message);
                    obj.client = [];
                    obj.session = [];
                    % Construct a questdlg with three options
                    choice = questdlg('OMERO logon failed!', ...
                    'Logon Failure!', ...
                    'Try again to logon','Run FLIMfit in non-OMERO mode','Run FLIMfit in non-OMERO mode');
                    % Handle response
                    switch choice
                        case 'Try again to logon'
                            keeptrying = true;                                                  
                        case 'Run FLIMfit in non-OMERO mode'
                            % no action keeptrying is already false                       
                    end    % end switch           
                end   % end catch
                if ~isempty(obj.session)
                    obj.client.enableKeepAlive(60); % Calls session.keepAlive() every 60 seconds
                    obj.userid = obj.session.getAdminService().getEventContext().userId;                                        
                end
            end     % end while     
            
       end
        
       
       %------------------------------------------------------------------                
        function Export_IRF_annot(obj,irf_data,~)
            
            selected = obj.select_for_annotation();
            
            if isempty(selected)
                return;
            end
                                           
            ext = '.irf';   
            irf_file_name = [tempdir 'IRF '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') ext];            
            % works - but why is it t axis distortion there if IRF is from single-plane-tif-averaging
            dlmwrite(irf_file_name,irf_data);            
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            file_mime_type = char('application/octet-stream');
            %
            add_Annotation(obj.session, obj.userid, ...
                            selected, ...
                            file_mime_type, ...
                            irf_file_name, ...
                            description, ...
                            namespace);                        
        end                
       %------------------------------------------------------------------                        
        function Export_TVB_annot(obj,data_series,~)
            
            selected = obj.select_for_annotation();
            
            if isempty(selected)
                return;
            end

            
            tvbdata = [data_series.t(:) data_series.tvb_profile(:)];
            %
            ext = '.txt';   
            tvb_file_name = [tempdir 'TVB '  datestr(now,'yyyy-mm-dd-T-HH-MM-SS') ext];            
            %
            dlmwrite(tvb_file_name,tvbdata);            
            %            
            namespace = 'IC_PHOTONICS';
            description = ' ';            
            file_mime_type = char('application/octet-stream');
            %
            add_Annotation(obj.session, obj.userid, ...
                            selected, ...
                            file_mime_type, ...
                            tvb_file_name, ...
                            description, ...
                            namespace);                                                            
        end                 
       %------------------------------------------------------------------        
        function Load_TVB_annot(obj,data_series,parent)
            
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Choose TVB file');
            %
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            %
            full_temp_file_name = [tempdir fname];
            fid = fopen(full_temp_file_name,'w');                
            fwrite(fid,str,'*uint8');                        
            fclose(fid);
            %
            try
                data_series.load_tvb(full_temp_file_name);
            catch err
                 [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
            end
            %
            delete(full_temp_file_name); %??            
        end                      
    %
        %------------------------------------------------------------------        
       
        function Import_Data_Settings(obj,data_series,parent)
            
            [str, fname] = select_Annotation(obj.session,obj.userid,parent,'Choose data settings file');
            
            if -1 == str
                errordlg('select_Annotation: no annotations - ret is empty');
                return;
            elseif isempty(str)                
                return;       
            end            
            
            data_series.load_data_settings(fname);
          
        end 
        
        %------------------------------------------------------------------
        % ask user to select a plate or dataset for adding annotations
        function selected = select_for_annotation(obj)
            
            selected = [];
            
            %choice = questdlg('Do you want to Export fitting settings to Dataset or Plate?', ' ', ...
            %                        'Dataset' , ...
            %                       'Plate','Cancel','Cancel');      
            
            % Use only dataset for now pemding Management decision re Plates.
            choice = 'Dataset';
            
            switch choice
                case 'Dataset',
                    chooser = OMEuiUtils.OMEROImageChooser(obj.client, obj.userid, int32(1));
                    selected = chooser.getSelectedDataset();
                    clear chooser
                case 'Plate', 
                    chooser = OMEuiUtils.OMEROImageChooser(obj.client, obj.userid, int32(1));
                    selected = chooser.getSelectedPlate();
                    clear chooser;
                case 'Cancel', 
                    return;
            end
            
            if isempty(selected)
                return;
            end
        end
        
        %------------------------------------------------------------------
        function Select_Another_User(obj,~)
                   
            ec = obj.session.getAdminService().getEventContext();
            AdminServicePrx = obj.session.getAdminService();            
                        
            groupids = toMatlabList(ec.memberOfGroups);                  
            gid = groupids(1); %default - first group is the current?                                   
            experimenter_list_g = AdminServicePrx.containedExperimenters(gid);
                                    
            z = 0;
            for exp = 0:experimenter_list_g.size()-1
                exp_g = experimenter_list_g.get(exp);
                z = z + 1;
                nme = [num2str(exp_g.getId.getValue) ' @ ' char(java.lang.String(exp_g.getOmeName().getValue()))];
                str(z,1:length(nme)) = nme;                                                
            end                
                        
            strcell_sorted = sort_nat(unique(cellstr(str)));
            str = char(strcell_sorted);
                                    
            EXPID = [];
            prompt = 'Please choose the user';
            [s,v] = listdlg('PromptString',prompt,...
                                        'SelectionMode','single',...
                                        'ListSize',[300 300],...                                        
                                        'ListString',str);                        
            if(v)
                expname = str(s,:);
                expnamesplit = split('@',expname);
                EXPID = str2num(char(expnamesplit(1)));
            end;                                            

            if ~isempty(EXPID) 
                obj.userid = EXPID;
            else
                obj.userid = obj.session.getAdminService().getEventContext().userId;                
            end                                                                     
            %
            obj.project = [];
            obj.dataset = [];
            obj.screen = [];
            obj.plate = [];
            %
        end                           
    end
end






























