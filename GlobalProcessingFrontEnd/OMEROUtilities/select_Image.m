        function ret = select_Image(Dataset)
            %
            ret = [];
            %
            if isempty(Dataset) 
                errordlg('Dataset not defined');
                return;
            end;                   
            %
            dName = char(java.lang.String(Dataset.getName().getValue()));
            imageList = Dataset.linkedImageList;
            %       
            if 0==imageList.size()
                errordlg(['Dataset ' dName ' have no images'])
                return;
            end;                                    
            %        
             z = 0;       
             str = char(256,256);
             for k = 0:imageList.size()-1,                       
                     z = z + 1;                                                       
                     iName = char(java.lang.String(imageList.get(k).getName().getValue()));                                                                
                     dName = char(java.lang.String(Dataset.getName().getValue()));
                     idName = num2str(imageList.get(k).getId().getValue());
                     image_name = [ idName ' : ' iName ]; 
                     str(z,1:length(image_name)) = image_name;
              end 
                        
            str = str(1:imageList.size(),:);
            %
            [s,v] = listdlg('PromptString',['Select an Image in ' dName ' Dataset'],...
                            'SelectionMode','single',...
                            'ListString',str);
            %
            if(v)
                ret = imageList.get(s-1);
            end;            
        end                      
