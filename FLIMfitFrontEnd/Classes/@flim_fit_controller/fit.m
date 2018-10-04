function fit(obj,varargin)

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

    try
    
        bin = false;
        roi_mask = [];
        dataset = [];
        
        if obj.fit_in_progress && obj.terminating
            return;
        end

        if obj.fit_in_progress

            obj.dll_interface.terminate_fit();
            obj.terminating = true;

        else

            if nargin == 2
                bin = varargin{1};
            elseif nargin >= 4
                bin = varargin{1};
                roi_mask = varargin{2};
                dataset = varargin{3};
            end
            
            delete(obj.fit_result);

            obj.fit_in_progress = true;
            obj.has_fit = false;

            if ~bin
                obj.display_fit_start();
            end

            row_headers = {'Thread' 'Num Completed' 'Cur Group' 'Iteration' 'Chi2'};
            set(obj.progress_table,'RowName',row_headers);

            obj.start_time = tic;

            if bin == false
                obj.dll_interface.fit(obj.data_series_controller.data_series, obj.fit_params);
            else
                if isempty(roi_mask)
                    roi_mask = obj.roi_controller.roi_mask;
                end
                if isempty(dataset)
                    dataset = obj.data_series_list.selected;
                end

                obj.dll_interface.fit(obj.data_series_controller.data_series, obj.fit_params, roi_mask, dataset);
            end
            
            obj.fit_timer = timer('TimerFcn',@(~,~) obj.update_progress(), 'ExecutionMode', 'fixedSpacing', 'Period', 0.1);
            start(obj.fit_timer)
            
        end

    catch e
        
        obj.fit_in_progress = false;
        obj.display_fit_end();
        throw(e);
    end
        
        
end