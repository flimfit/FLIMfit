function handles = add_fitting_params_panel(obj,handles,parent)

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

    
    % Fit Params Panel
    %---------------------------------------
    fit_params_panel = uitabgroup('Parent', parent);
    
    % Main Tab
    fit_tab = uitab('Parent', fit_params_panel, 'Title', 'Model');
    fit_tab_layout = uigridlayout(fit_tab, [1,1], 'Padding', 3);
    
    handles.model_panel = uipanel('Parent',fit_tab_layout);
    
    % Advanced tab
    adv_tab = uitab('Parent', fit_params_panel, 'Title', 'Advanced');
    adv_layout = uigridlayout(adv_tab, [1,3], 'ColumnSpacing', 1, 'Padding', 3, 'ColumnWidth', {200 150});
    label_layout = uigridlayout(adv_layout, [10,1],  'RowSpacing', 1);
    opt_layout = uigridlayout(adv_layout, [10,1],  'RowSpacing', 1);
    
    add_fitting_param_control('n_thread','edit','No. Threads', '4');
    add_fitting_param_control('global_scope','popupmenu','Global Mode', {'Pixel-wise','Image-wise','Global'});
    add_fitting_param_control('fitting_algorithm','popupmenu','Algorithm', {'Variable Projection' 'Maximum Likelihood'});
    add_fitting_param_control('use_numerical_derivatives','popupmenu','Use Numerical Derivatives', {'No', 'Yes'});
    add_fitting_param_control('weighting_mode','popupmenu','Weighting Mode', {'Average Data','Pixelwise Data'});
    add_fitting_param_control('use_autosampling','popupmenu','Use Autosampling', {'No','Yes'});
    add_fitting_param_control('image_irf_mode','popupmenu','IRF',{'Single Point', 'Use SV IRF', 'Use IRF Shift Map'});

    add_fitting_param_control('live_update','popupmenu','Live Fit', {'No', 'Yes'});
    add_fitting_param_control('calculate_errs','popupmenu','Calculate Errors', {'No', 'Yes'});
    add_fitting_param_control('use_image_t0_correction','popupmenu','Use FOV IRF shift', {'No', 'Yes'});
    
    label_layout_sizes = num2cell(22*ones(1,length(opt_layout.Children)));        
    set([label_layout opt_layout],'RowHeight',label_layout_sizes);
    
    
    function add_fitting_param_control(name, style, label, string)
        
        label = uilabel('Text', [label '  '], 'HorizontalAlignment', 'right', 'Parent', label_layout); 
        
        switch style
            case 'popupmenu'
                control = uidropdown('Items', string, 'Parent', opt_layout);
            case 'edit'
                control = uieditfield('Value', string, 'Parent', opt_layout);
        end
        
        handles.([name '_label']) = label;
        handles.([name '_' style]) = control;
                
    end

end