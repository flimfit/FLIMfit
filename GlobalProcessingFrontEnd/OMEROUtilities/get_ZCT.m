        function dims = get_ZCT( image, modulo, sizet )

          pixelsList = image.copyPixels();    
                pixels = pixelsList.get(0);
            %
            Z = pixels.getSizeZ().getValue();            
            C = pixels.getSizeC().getValue();
            T = pixels.getSizeT().getValue();
            %
            dims{1} = 1;
            dims{2} = 1;
            dims{3} = 1;
            
            if ~isempty(modulo)                
                switch modulo
                    case 'ModuloAlongZ'
                        Z = Z/sizet;                 
                    case 'ModuloAlongC'
                        C = C/sizet;                                       
                    case 'ModuloAlongT'
                        T = T/sizet;
                end
            end 
            if (Z + C + T) > 3
                dims = ZCT_chooser({Z,C,T});
            end
            
          
end

