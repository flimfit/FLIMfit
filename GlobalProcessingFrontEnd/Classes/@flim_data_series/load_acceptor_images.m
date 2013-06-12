function load_acceptor_images(obj,path)

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

    if isdir(path)
    
        path = ensure_trailing_slash(path);

        obj.acceptor = zeros([obj.height obj.width obj.n_datasets]);

        options = acceptor_options_dialog();

        if ~isempty(options.background)
            bg = double(imread(options.background));
            % correct for labview broken tiffs
            if all(bg > 2^15)
                bg = bg - 2^15;
            end
        else
            bg = 0;
        end

        h = waitbar(0,'Loading Acceptor Images...');
        for i=1:obj.n_datasets

            items =  dir([path '*' obj.names{i} '*']);

            if ~isempty(items)

                item = items(1);

                im = [];

                if item.isdir
                    items =  dir([path item.name '\']);
                    im = load_flim([path item.name '\'],items);
                else
                    im = load_flim(path,items);
                end


                if ~isempty(im)
                    im = medfilt2(im,[7 7]);

                    if bg == 0
                        im = im - min(im(:));
                    else
                        im = im - bg;
                    end

                    if options.align
                        intensity = obj.integrated_intensity(i);
                        im = align_images(im, intensity, true);
                    end

                    obj.acceptor(:,:,i) = im;

                end


            end
            waitbar(i/obj.n_datasets,h);
        end
        close(h);
    else
        % import labelled tif stack        

        obj.acceptor = ReadSelectedFromTiffStack(path,obj.names,'Acceptor');
        obj.acceptor(isnan(obj.acceptor)) = 0;
        
    end
    
    function im = load_flim(path,items)
       
        im = [];
        
        for j=1:length(items)
           
            [~,~,ext] = fileparts(items(j).name);
            
            if strcmp(ext,'.tif')
                im = [path items(j).name];
                break;
            end
                        
        end
        
        if ~isempty(im)
            [~,data] = load_flim_file(im);

            im = squeeze(mean(mean(data,1),2));
        end
        
    end

end