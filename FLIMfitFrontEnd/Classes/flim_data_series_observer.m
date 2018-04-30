classdef flim_data_series_observer < handle
    
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
        data_series;
        data_series_controller;
        ds_lh;
    end
    
    methods
        function obj = flim_data_series_observer(data_series_controller)
           obj.data_series_controller = data_series_controller; 
           
           if ~isempty(data_series_controller)
               addlistener(data_series_controller,'new_dataset',@(src,evt) EC(@obj.update_data_series));
               obj.set_data_series(data_series_controller.data_series);
           end
        end
        
        function update_data_series(obj)
            obj.set_data_series(obj.data_series_controller.data_series);
        end
        
        function set_data_series(obj, data_series)
            obj.data_series = data_series; 
            delete(obj.ds_lh);
            obj.ds_lh = addlistener(obj.data_series,'data_updated',@(~,~) EC(@obj.data_update_evt));
            obj.data_set();

            if obj.data_series.init
                obj.data_update();
            end
        end
        
        function data_update_evt(obj)
            if ~ishandle(obj.data_series) && obj.data_series.init
                obj.data_update();
            end
        end

        % override this
        function data_set(obj) 
        end

                 
    end
    
    methods(Abstract = true)
        data_update(obj);
    end
end