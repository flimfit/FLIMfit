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


    children = get(obj.plot_panel,'Children');
    if ~isempty(children)
        for i=1:length(children)
            delete(children(i))
        end
    end
    
    if ~obj.fit_controller.has_fit || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
        return
    end
    
    f = obj.fit_controller;
    r = f.fit_result;
        
    
    if nargin == 2
        f_save = figure('visible','on');        
        save = true;
        [path,root,ext] = fileparts(file_root);
        ext = ext(2:end);
        root = [path filesep root];
    else
        save = false;
    end

    if ~save && obj.dataset_selected == 0;
        return
    end;
    
    n = ceil(sqrt(f.n_plots));   
    m = ceil(f.n_plots/n);

  
    if f.n_plots>0 && ~save
        [ha,hc] = tight_subplot(obj.plot_panel,f.n_plots,m,n,save,[r.width r.height],5,5,5);
    end
    
    if ~save
        ims = obj.dataset_selected;
    else
        ims = 1:r.n_results;
    end
    
    for cur_im = ims

        if save
            name_root = [root ' ' r.names{cur_im}];
        end

        subplot_idx = 1;

        if f.n_plots > 0

            for plot_idx = 1:length(f.plot_names)
            
                if f.display_normal.(f.plot_names{plot_idx})
                    
                    if ~save
                        h = ha(subplot_idx);
                        c = hc(subplot_idx);
                    else
                        [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);
                    end
                    
                    im_data = obj.plot_figure(h,c,cur_im,plot_idx,false,'');
                    
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' r.params{plot_idx}],ext)
                        SaveFPTiff(im_data,[name_root ' ' r.params{plot_idx} ' raw.tiff'])
                    end
                end

                % Merge
                if f.display_merged.(f.plot_names{plot_idx})
                    if ~save
                        h = ha(subplot_idx);
                        c = hc(subplot_idx);
                    else
                        [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);
                    end
                    
                    obj.plot_figure(h,c,cur_im,plot_idx,true,'');
                  
                    subplot_idx = subplot_idx + 1;
                    if save
                        savefig([name_root ' ' r.params{plot_idx} ' merge'],ext)
                    end
                end
                
            end

        end      
    end
    
    if save
        close(f_save)
    end
end

