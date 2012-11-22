        function ZCT = get_ZCT( image, modulo )

          pixelsList = image.copyPixels();    
                pixels = pixelsList.get(0);
            %
            maxZ = pixels.getSizeZ().getValue();            
            maxC = pixels.getSizeC().getValue();
            maxT = pixels.getSizeT().getValue();
            %
            dims = {1,1,1};
            if ~isempty(modulo)                
                switch modulo
                    case 'ModuloAlongZ'
                        if ~(1==maxC && 1==maxT)
                            dims = ZCT_chooser({1,maxC,maxT});
                        end                    
                    case 'ModuloAlongC'
                        if ~(1==maxZ && 1==maxT)
                            dims = ZCT_chooser({maxZ,1,maxT});
                        end                                        
                    case 'ModuloAlongT'
                        if ~(1==maxZ && 1==maxC)
                            dims = ZCT_chooser({maxZ,maxC,1});
                        end
                end
            end            
            %
            ZCT  = cell2mat(dims);
end

