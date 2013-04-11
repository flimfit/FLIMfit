function imageId = upload_Image_OME_tif(factory,dataset,filename,description) 

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
        
    ometiffdata = OME_tif2Omero_Image(factory,filename,description);

    imageId = ometiffdata.imageId;
    s = ometiffdata.s;
    
    if isempty(imageId) || isempty(dataset), errordlg('bad input'); return; end;                   

    detached_metadata_xml_filename = [tempdir 'metadata.xml'];
    fid = fopen(detached_metadata_xml_filename,'w');    
        fwrite(fid,s,'*uint8');
    fclose(fid);
        
    link = omero.model.DatasetImageLinkI;
    link.setChild(omero.model.ImageI(imageId, false));
    link.setParent(omero.model.DatasetI(dataset.getId().getValue(), false));
    factory.getUpdateService().saveAndReturnObject(link);

    myimages = getImages(factory,imageId.getValue()); image = myimages(1);        
        
    namespace = 'IC_PHOTONICS';
    description = ' ';
    %
    sha1 = char('pending');
    file_mime_type = char('application/octet-stream');
    %
    add_Annotation(factory, ...
                    image, ...
                    sha1, ...
                    file_mime_type, ...
                    detached_metadata_xml_filename, ...
                    description, ...
                    namespace);    
    %
    delete(detached_metadata_xml_filename);  
    
    % use "s" to create XML annotation
    [parseResult,~] = xmlreadstring(s);
    tree = xml_read(parseResult);
            
            modlo = [];
            modulo = [];
            FLIM_type = [];
            Delays = [];
            
            if isfield(tree,'ModuloAlongC')
                modlo = tree.ModuloAlongC;
                modulo = 'ModuloAlongC';
            elseif isfield(tree,'ModuloAlongT')
                modlo = tree.ModuloAlongT;
                modulo = 'ModuloAlongT';
            elseif  isfield(tree,'ModuloAlongZ')
                modlo = tree.ModuloAlongZ;
                modulo = 'ModuloAlongZ';
            end   
            %
            if ~isempty(modlo)
                if isfield(modlo.ATTRIBUTE,'Start')
                    start = modlo.ATTRIBUTE.Start;
                    step = modlo.ATTRIBUTE.Step;
                    e = modlo.ATTRIBUTE.End;                
                    Delays = start:step:e;
                elseif isfield(modlo.Label)
                    str_delays = modlo.Label;
                    Delays = cell2mat(str_delays);
                end
                %    
                if isfield(modlo.ATTRIBUTE,'Description')
                    FLIM_type = modlo.ATTRIBUTE.Description;
                end
            end
                        
            if isfield(tree,'SA_COLON_StructuredAnnotations') % supposed to be here...
                
                if  isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongT') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Type)

                    modulo = 'ModuloAlongT';
                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Start')
                        start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Start;
                        step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Step;
                        e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.End;                
                        Delays = start:step:e;
                    else
                        str_delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.Label;
                        Delays = cell2mat(str_delays);
                    end

                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Unit')
                        if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Unit,'ns')
                            Delays = Delays*1000; % assumes units are ps  unless specified as ns
                        end
                    end
                    
                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE,'Description')
                        FLIM_type = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongT.ATTRIBUTE.Description;
                    end                    

                elseif isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongC') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Type)

                    modulo = 'ModuloAlongC';
                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Start')
                        start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Start;
                        step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Step;
                        e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.End;                
                        Delays = start:step:e;
                    else
                        str_delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.Label;
                        Delays = cell2mat(str_delays);
                    end

                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Unit')
                        if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Unit,'ns')
                            Delays = Delays*1000; % assumes units are ps  unless specified as ns
                        end
                    end
                    
                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE,'Description')
                        FLIM_type = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongC.ATTRIBUTE.Description;
                    end                    
                                                                                                  
                elseif isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo,'ModuloAlongZ') && strcmp('lifetime',tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Type)     
                                                            
                    modulo = 'ModuloAlongZ';
                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Start')
                        start = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Start;
                        step = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Step;
                        e = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.End;                
                        Delays = start:step:e;
                    else
                        str_delays = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.Label;
                        Delays = cell2mat(str_delays);
                    end

                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Unit')
                        if strfind(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Unit,'ns')
                            Delays = Delays*1000; % assumes units are ps  unless specified as ns
                        end
                    end
                    
                    if isfield(tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE,'Description')
                        FLIM_type = tree.SA_COLON_StructuredAnnotations.SA_COLON_XMLAnnotation.SA_COLON_Value.Modulo.ModuloAlongZ.ATTRIBUTE.Description;
                    end                    
                                        
                end

                if isempty(FLIM_type)
                    if isfield(tree.Image,'HRI'), FLIM_type = 'Gated'; end;
                    if isfield(tree.Image,'FLIMType'), FLIM_type = tree.Image.FLIMType; end;
                end
                
                if isempty(FLIM_type) FLIM_type = 'TCSPC'; end; % aaaaaa!!!
                                                
            end        
                        
    % last chance that it is LaVision modulo Z format..
    if isempty(Delays) && isempty(modulo) && isempty(FLIM_type)    
        pixelsList = image.copyPixels();    
        pixels = pixelsList.get(0);                        
        SizeC = pixels.getSizeC().getValue();
        SizeZ = pixels.getSizeZ().getValue();
        SizeT = pixels.getSizeT().getValue();
        %
        if 1 == SizeC && 1 == SizeT && SizeZ > 1
            if isfield(tree.Image.Pixels.ATTRIBUTE,'PhysicalSizeZ')
                physSizeZ = tree.Image.Pixels.ATTRIBUTE.PhysicalSizeZ*1000;     % assume this is in ns so convert to ps
                Delays = (0:SizeZ-1)*physSizeZ;
                modulo = 'ModuloAlongZ';
                FLIM_type = 'TCSPC';
            end
        end                        
    end
    %
    if ~isempty(Delays) && ~isempty(modulo) && ~isempty(FLIM_type)
        xmlnode = create_ModuloAlongDOM(Delays, [], modulo, FLIM_type);
        add_XmlAnnotation(factory,image,xmlnode);
        %
        add_Original_Metadata_Annotation(factory,image,filename);
        %
    end           
    %             
end
    