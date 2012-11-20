function im_data = plot_figure(obj,h,hc,dataset,im,merge,text)

    if isempty(obj.fit_controller.fit_result) || (~isempty(obj.fit_controller.fit_result.binned) && obj.fit_controller.fit_result.binned == 1)
        return
    end
    intensity = obj.fit_controller.get_intensity(dataset);
    im_data = obj.fit_controller.get_image(dataset,im);
    
    invert = get(obj.invert_colormap_popupmenu,'Value') - 1;
    
    if strcmp(im,'I0') || strcmp(im,'I')
        cscale = @gray;
    elseif invert && (~isempty(strfind(im,'tau')) || ~isempty(strfind(im,'theta')))
        cscale = @inv_jet;
    else
        cscale = @jet;
    end
    
    if ~merge
        colorbar_flush(h,hc,im_data,isnan(intensity),obj.plot_lims.(obj.plot_names{im}),cscale,text);
    else
        colorbar_flush(h,hc,im_data,[],obj.plot_lims.(obj.plot_names{im}),cscale,text,intensity,obj.plot_lims.I);
    end

end