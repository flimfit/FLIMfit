function im_data = plot_figure(obj,h,hc,dataset,im,merge,text)

    f = obj.fit_controller;

    if isempty(f.fit_result) || (~isempty(f.fit_result.binned) && f.fit_result.binned == 1)
        return
    end
    intensity = f.get_intensity(dataset);
    im_data = f.get_image(dataset,im);
    invert = f.invert_colormap;
    
    if strcmp(im,'I0') || strcmp(im,'I')
        cscale = @gray;
    elseif invert && (~isempty(strfind(im,'tau')) || ~isempty(strfind(im,'theta')))
        cscale = @inv_jet;
    else
        cscale = @jet;
    end
    
    lims = f.get_cur_lims(im);
    I_lims = f.get_cur_intensity_lims();
    
    if ~merge
        colorbar_flush(h,hc,im_data,isnan(intensity),lims,cscale,text);
    else
        colorbar_flush(h,hc,im_data,[],lims,cscale,text,intensity,I_lims);
    end

end