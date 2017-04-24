function handles = add_data_transformation_panel(obj,handles,parent)

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


   % dataset
    dataset_panel = uix.TabPanel( 'Parent', parent, 'TabWidth', 80 );
 

    % data transformation
    data_layout = uix.VBox( 'Parent', dataset_panel );
    data_transformation_layout = uix.Grid( 'Parent', data_layout, 'Spacing', 1, 'Padding', 3  );
    uicontrol( 'Style', 'text', 'String', 'Smoothing ',       'HorizontalAlignment', 'right', 'Parent', data_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Integrated Min. ', 'HorizontalAlignment', 'right', 'Parent', data_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Time Min. ',    'HorizontalAlignment', 'right', 'Parent', data_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Counts/Photon ',    'HorizontalAlignment', 'right', 'Parent', data_transformation_layout );
    
    handles.binning_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'None', '3x3 (B&H 1)', '5x5 (B&H 2)', '7x7 (B&H 3)' '9x9 (B&H 4)' '11x11 (B&H 5)' '13x13 (B&H 6)' '15x15 (B&H 7)'}, 'Parent', data_transformation_layout );
    handles.thresh_min_edit   = uicontrol( 'Style', 'edit', 'String', '0', 'Parent', data_transformation_layout );
    handles.t_min_edit        = uicontrol( 'Style', 'edit', 'String', '0', 'Parent', data_transformation_layout );
    handles.counts_per_photon_edit = uicontrol( 'Style', 'edit', 'String', '0', 'Parent', data_transformation_layout );
    
    uicontrol( 'Style', 'text', 'String', 'Rep. Rate ', 'HorizontalAlignment', 'right', 'Parent', data_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Gate Max. ',    'HorizontalAlignment', 'right', 'Parent', data_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Time Max. ',    'HorizontalAlignment', 'right', 'Parent', data_transformation_layout );
    uix.Empty( 'Parent', data_transformation_layout );
    
    handles.rep_rate_edit          = uicontrol( 'Style', 'edit', 'String', '80', 'Parent', data_transformation_layout );
    handles.gate_max_edit          = uicontrol( 'Style', 'edit', 'String', '1e10', 'Parent', data_transformation_layout );
    handles.t_max_edit             = uicontrol( 'Style', 'edit', 'String', '1e10', 'Parent', data_transformation_layout );
    uix.Empty( 'Parent', data_transformation_layout );
    
    set(data_transformation_layout,'Heights',[22 22 22 22]);
    set(data_transformation_layout,'Widths',[120 120 120 120]);   
    
      
    handles.background_container = uicontainer( 'Parent', data_layout ); 
    handles.background_axes = axes( 'Parent', handles.background_container );
    
    set(data_layout,'Heights',[150 -1]);
    
    % background
    background_layout = uix.VBox( 'Parent', dataset_panel );
    background_layout = uix.Grid( 'Parent', background_layout, 'Spacing', 1, 'Padding', 3  );
    
    uicontrol( 'Style', 'text', 'String', 'Background ', 'HorizontalAlignment', 'right', 'Parent', background_layout );
    uicontrol( 'Style', 'text', 'String', 'Background Value ', 'HorizontalAlignment', 'right', 'Parent', background_layout );
    
    handles.background_type_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'None', 'Single Value', 'Image', 'TV Intensity Map'}, 'Parent', background_layout );
    handles.background_value_edit = uicontrol( 'Style', 'edit', 'String', '0', 'Parent', background_layout );
    %handles.tvb_define_pushbutton = uicontrol( 'Style', 'pushbutton', 'String', 'Define', 'Parent', background_layout );
    
    
    set(background_layout,'Heights',[22 22]);
    set(background_layout,'Widths',[120 120]);
    
    % irf transformation
    irf_layout = uix.VBox( 'Parent', dataset_panel );
    irf_transformation_layout = uix.Grid( 'Parent', irf_layout, 'Spacing', 1, 'Padding', 3 );

    uicontrol( 'Style', 'text', 'String', 'IRF Type ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Background ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Time Min. ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'IRF Shift ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
    
    handles.irf_type_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'Scatter', 'Reference'}, 'Parent', irf_transformation_layout );
    handles.irf_background_edit = uicontrol( 'Style', 'edit', 'String', '0', 'Parent', irf_transformation_layout );
    handles.t_irf_min_edit = uicontrol( 'Style', 'edit', 'String', '0', 'Parent', irf_transformation_layout );
    handles.t0_edit = uicontrol( 'Style', 'edit', 'String', '0', 'Parent', irf_transformation_layout );    
    
    
    uicontrol( 'Style', 'text', 'String', 'Reference Lifetime ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'BG is Afterpulsing ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'Time Max. ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
    uicontrol( 'Style', 'text', 'String', 'G Factor ', 'HorizontalAlignment', 'right', 'Parent', irf_transformation_layout );
       
    handles.ref_lifetime_edit = uicontrol( 'Style', 'edit', 'String', '80', 'Parent', irf_transformation_layout );
    handles.afterpulsing_correction_popupmenu = uicontrol( 'Style', 'popupmenu', 'String', {'No', 'Yes'}, 'Parent', irf_transformation_layout );
    handles.t_irf_max_edit = uicontrol( 'Style', 'edit', 'String', '1e10', 'Parent', irf_transformation_layout );
    handles.g_factor_edit = uicontrol( 'Style', 'edit', 'String', '1', 'Parent', irf_transformation_layout );
    
    
    set(irf_transformation_layout,'Heights',[22 22 22 22]);
    set(irf_transformation_layout,'Widths',[120 120 120 120]);

    
    % testing
    testing_layout = uix.VBox( 'Parent', dataset_panel );
    testing_layout = uix.Grid( 'Parent', testing_layout, 'Spacing', 1, 'Padding', 3  );
    
    uicontrol( 'Style', 'text', 'String', 'Data Subsampling ', 'HorizontalAlignment', 'right', 'Parent', testing_layout );
    uicontrol( 'Style', 'text', 'String', 'IRF Subsampling ', 'HorizontalAlignment', 'right', 'Parent', testing_layout );
    
    handles.data_subsampling_edit = uicontrol( 'Style', 'edit', 'String', '1', 'Parent', testing_layout );
    handles.irf_subsampling_edit = uicontrol( 'Style', 'edit', 'String', '1', 'Parent', testing_layout );
    
    
    set(testing_layout,'Heights',[22 22]);
    set(testing_layout,'Widths',[120 120]);
    
    
    
    
    
    
    set(dataset_panel, 'TabTitles', {'Data'; 'Background'; 'IRF'; 'Testing'});
    set(dataset_panel, 'Selection', 1);

    

end