function update_plots(obj,file_root)

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


    % TODO: seperate save/display
    
    r = obj.result_controller.fit_result;
    
    if isempty(r) || r.binned
        return
    end
    
    f = obj.result_controller;
    r = f.fit_result;
    
    
    if nargin == 2
        save = true;
        [path,root,ext] = fileparts(file_root);
        ext = ext(2:end);
        root = [path filesep root];
    else
        save = false;
    end

    if ~save && ~any(r.datasets == obj.dataset_selected)
        cla(obj.plot_axes);
        return
    end
    
    n = ceil(sqrt(f.n_plots));   
    m = ceil(f.n_plots/n);

    
    if save
        ims = 1:r.n_results;
        indexing = 'result';
    else
        ims = obj.dataset_selected;
        indexing = 'dataset';
    end
    
    if ~save
        pos = get(obj.plot_panel,'Position');
        pos(1:2) = 10;
        pos(3:4) = pos(3:4) - 20;
        if (min(pos(3:4)) > 0)
            set(obj.plot_axes,'Units','pixels','Position',pos);
        end
    end
    
    figs = {};
    
    options = struct();
    
    for cur_im = ims
        
        if save
            % replace any full-stops in name with an underscore 
            % full stops seem to be interpreted as start of an extension
             name = r.names{cur_im};
             name = strrep(name,'.','_');
             name_root = [root ' ' name];
        end

        subplot_idx = 1;
        
        if save
            if any(strcmp({'tif','tiff'},ext))
                description_field_name = 'Description';
            else
                description_field_name = 'Comment';
            end
        end
        
        if f.n_plots > 0

            for plot_idx = 1:length(f.plot_names)
            
                if f.display_normal(f.plot_names{plot_idx})
                    
                    [fig, im_data, lims] = obj.plot_figure2(cur_im, plot_idx, false, options, indexing);
                    figs{subplot_idx} = double(fig);
                    
                    description = ['Limits: ' num2str(lims(1)) ' - ' num2str(lims(2))];
                                        
                    if save
                        imwrite(uint8(fig*255),[name_root ' ' r.params{plot_idx} '.' ext],description_field_name,description);
                        SaveFPTiff(im_data,[name_root ' ' r.params{plot_idx} ' raw.tif'])
                    end
                    subplot_idx = subplot_idx + 1;
                end

                % Merge
                if f.display_merged(f.plot_names{plot_idx})
                    
                    [fig, ~, lims] = obj.plot_figure2(cur_im, plot_idx, true, options, indexing);
                    figs{subplot_idx} = double(fig);
                    
                    description = ['Limits: ' num2str(lims(1)) ' - ' num2str(lims(2))];
                    
                    subplot_idx = subplot_idx + 1;
                    if save
                        imwrite(uint8(fig*255),[name_root ' ' r.params{plot_idx} ' merge.' ext],description_field_name,description);
                    end
                end
                
            end

        end      
    end
    
    if ~save 
        if f.n_plots > 0
            
            if verLessThan('matlab','9.4')
                figs = reshape(figs,[1 1 1 length(figs)]);
                figs = cell2mat(figs);            
            end
            
            montage(figs,'Size',[m n],'Parent',obj.plot_axes);
        end
    end
end

% work-around to enlarge small images to avoid oversized text 
function winsize = size_check(width,height)

while width < 100 && height < 100
    width = width .* 2;
    height = height .* 2;
end
winsize = [width height];

end

