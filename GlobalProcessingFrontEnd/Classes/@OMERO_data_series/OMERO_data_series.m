classdef OMERO_data_series < flim_data_series
    
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

   
    properties
        
        image_ids;
        mdta;
       
        ZCT; % cell array containing missing OME dimensions Z,C,T (in that order)  
        verbose;        % flag to switch waitbar in OMERO_fetch on or off
        
        session;
        
    end
    
    properties(Constant)
        
    end
    
    properties(SetObservable)
         
    end
    
    properties(Dependent)
        
    end
    
    properties(SetObservable,Transient)
        
    end
        
    properties(SetObservable,Dependent)
       
    end
    
    properties(Transient)
        
    end
    
    properties(Transient,Hidden)
        % Properties that won't be saved to a data_settings_file or to 
        % a project file
        
    end
    
    events
        
    end
    
    methods(Static)
             
    end
    
    methods
        
     function obj = OMERO_data_series(varargin)            
            handles = args2struct(varargin);
            assign_handles(obj,handles);
            verbose = true;
            
            polarisation_resolved = false;  % defaults
            load_multiple_channels = false;
            
        end
                                        
        function delete(obj)
        end   
        
        
        
    end
    
end