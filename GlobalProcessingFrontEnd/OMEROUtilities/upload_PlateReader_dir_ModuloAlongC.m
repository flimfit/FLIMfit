
function objId = upload_PlateReader_dir_ModuloAlongC(session, parent, folder, fov_name_parse_function)

    objId = [];    
    if isempty(parent) || isempty(folder), return, end;    

    PlateSetups = feval(fov_name_parse_function,folder);
       
    str = split(filesep,folder);
    newdataname = str(length(str));
    
    whos_parent = whos_Object(session,parent.getId().getValue());
    
    if strcmp('Screen',whos_parent) % append new Plate: data -> Plate -> Screen
        updateService = session.getUpdateService();        
            newdata = omero.model.PlateI();
            newdata.setName(omero.rtypes.rstring(newdataname));    
            newdata.setColumnNamingConvention(omero.rtypes.rstring(PlateSetups.columnNamingConvention));
            newdata.setRowNamingConvention(omero.rtypes.rstring(PlateSetups.rowNamingConvention));            
            newdata = updateService.saveAndReturnObject(newdata);
            link = omero.model.ScreenPlateLinkI;
            link.setChild(newdata);            
            link.setParent(omero.model.ScreenI(parent.getId().getValue(),false));            
        updateService.saveObject(link);        
    elseif strcmp('Project',whos_parent) % append new Dataset: data -> Dataset -> Project
            description = [ 'new dataset created at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
            newdata = create_new_Dataset(session,parent,newdataname,description);                            
    end

    objId = newdata.getId().getValue();        
    upload_PlateReader_dir_as_Channels_FLIM_Data(session,folder,newdata,PlateSetups);

end