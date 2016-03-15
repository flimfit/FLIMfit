%> @ingroup UserInterfaceControllers
classdef flim_omero_logon_manager < handle 
    
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
        
        function obj = flim_omero_logon_manager(varargin)            
            handles = args2struct(varargin);
            assign_handles(obj,handles);
            dataset = [];
            plate = [];
            
        end
                                        
        function delete(obj)
        end
        
        function setDataset(obj, dset) 
            obj.dataset = dset;
            obj.plate = [];
        end
        
        function setPlate(obj, pl) 
            obj.dataset = [];
            obj.plate = pl;
        end
                                
       
        %------------------------------------------------------------------
                    
        function Omero_logon(obj,~) 
            
            settings = [];
            
            keeptrying = true;
           
            while keeptrying
                
            if ~ispref('GlobalAnalysisFrontEnd','OMEROlogin')
                neverTriedLog = true;       % set flag if the OMERO dialog login has never been called on this machine
            else
                neverTriedLog = false;
            end
            
            obj.logon = OMERO_logon();
           
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






























