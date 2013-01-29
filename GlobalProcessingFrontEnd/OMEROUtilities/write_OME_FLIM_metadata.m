function xmlFileName = write_OME_FLIM_metadata(ome_params)

h = ome_params.SizeX;
w = ome_params.SizeY;
    SizeZ = ome_params.SizeZ;
    SizeC = ome_params.SizeC;
    SizeT = ome_params.SizeT;
modulo = ome_params.modulo;
delays = ome_params.delays;
num_delays = numel(delays);

OMEnode = com.mathworks.xml.XMLUtils.createDocument('OME');
OME = OMEnode.getDocumentElement;
OME.setAttribute('xmlns','http://www.openmicroscopy.org/Schemas/OME/2011-06');
OME.setAttribute('xmlns:SA','http://www.openmicroscopy.org/Schemas/SA/2011-06');
    Image = OMEnode.createElement('Image');
        Pixels = OMEnode.createElement('Pixels');
        Pixels.setAttribute('BigEndian',ome_params.BigEndian);
        Pixels.setAttribute('DimensionOrder',ome_params.DimensionOrder);
        Pixels.setAttribute('ID','?????');
        Pixels.setAttribute('PixelType',ome_params.pixeltype);
        Pixels.setAttribute('SizeX',num2str(h));
        Pixels.setAttribute('SizeY',num2str(w));
        Pixels.setAttribute('SizeZ',num2str(SizeZ));
        Pixels.setAttribute('SizeC',num2str(SizeC));
        Pixels.setAttribute('SizeT',num2str(SizeT));        
    %
    StructuredAnnotations = OMEnode.createElement('SA:StructuredAnnotations');
        XMLAnnotation = OMEnode.createElement('SA:XMLAnnotation');
            XMLAnnotation.setAttribute('ID','Annotation:3');        
            XMLAnnotation.setAttribute('Namespace','openmicroscopy.org/omero/dimension/modulo'); 
                Value = OMEnode.createElement('SA:Value');
                    Modulo = OMEnode.createElement('Modulo');
                    Modulo.setAttribute('namespace','http://www.openmicroscopy.org/Schemas/Additions/2011-09');
                                        
                        switch modulo
                            case 'ModuloAlongC'
                                Pixels.setAttribute('SizeC',num2str(max(SizeC,num_delays)));
                                ModuloAlong = OMEnode.createElement('ModuloAlongC');                                
                            case 'ModuloAlongZ'
                                Pixels.setAttribute('SizeZ',num2str(max(SizeZ,num_delays)));
                                ModuloAlong = OMEnode.createElement('ModuloAlongZ');                                                            
                            case 'ModuloAlongT'                            
                                Pixels.setAttribute('SizeT',num2str(max(SizeT,num_delays)));
                                ModuloAlong = OMEnode.createElement('ModuloAlongT');                                                                                        
                        end           
                        
                                ModuloAlong.setAttribute('Type','lifetime');
                                ModuloAlong.setAttribute('Unit','ps');
                    
                                for i=1:numel(delays)
                                    thisElement = OMEnode.createElement('Label'); 
                                    thisElement.appendChild(OMEnode.createTextNode(num2str(delays{i})));
                                    ModuloAlong.appendChild(thisElement);
                                end
                                
                    Modulo.appendChild(ModuloAlong);                                                                                
                Value.appendChild(Modulo);
            XMLAnnotation.appendChild(Value);                        
    StructuredAnnotations.appendChild(XMLAnnotation);
           
    Image.appendChild(Pixels);                        
    
    if isfield(ome_params,'FLIMType')
        FLIMType = OMEnode.createElement('FLIMType');
        FLIMType.appendChild(OMEnode.createTextNode(ome_params.FLIMType));
        Image.appendChild(FLIMType);                        
    end
    
    if isfield(ome_params,'ContentsType')
        ContentsType = OMEnode.createElement('ContentsType');        
        ContentsType.appendChild(OMEnode.createTextNode(ome_params.ContentsType));
        Image.appendChild(ContentsType);                        
    end;
    
OME.appendChild(Image);
OME.appendChild(StructuredAnnotations);

xmlFileName = [tempdir 'metadata.xml'];
xmlwrite(xmlFileName,OME);
%type(xmlFileName);

end