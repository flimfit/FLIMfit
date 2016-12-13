classdef bioformats_reader < base_data_reader
   
    properties
        bf_reader;
        modulo;
    end
    
    methods
       
        function obj = bioformats_reader(filename, bf_reader)
            obj.filename = filename;
            obj.bf_reader = bf_reader;

            obj.ome_meta = obj.bf_reader.getMetadataStore();
            series_count = obj.bf_reader.getSeriesCount;

            if series_count > 1
                if obj.ome_meta.getPlateCount > 0
                    % plate! so check image_series has been setup or throw error
                    if obj.image_series == -1 || length(obj.image_series) ~= length(obj.file_names)
                        obj.error_message = ' This file contains Plate data. Please load using the appropriate menu item';
                        return;
                    end
                else
                    str = num2str((0:series_count - 1)');
                    prompt = [{sprintf(['This file holds ' num2str(series_count) ' images. Numbered 0-' num2str(series_count -1) '\nPlease select one'])} {''}];
                    image_series = listdlg('PromptString',prompt,'SelectionMode','single','ListString',str);
                    if isempty(image_series)
                        return;
                    end

                    % set series for each file to that selected 
                    obj.image_series = ones(1,length(obj.file_names)) .* image_series; 
                end
            else
                obj.image_series = 1;
            end

            obj.bf_reader.setSeries(obj.image_series(1) - 1);

            % NB note the inversion of X & Y here 
            obj.sizeXY = [r.getSizeY r.getSizeX];
            obj.sizeZCT = [r.getSizeZ r.getSizeC r.getSizeT];

            % check for presence of an Xml modulo Annotation  containing 'lifetime'

            search = {'T','C','Z'};
            modlo = [];
            for i=1:length(search)
                mod = eval(['r.getModulo' search{i} '();']);
                if strfind(lower(mod.type),'lifetime')
                    modlo = mod;
                    obj.modulo = ['ModuloAlong' search{i}];
                    break;
                end
            end

            if ~isempty(modlo)

                if ~isempty(modlo.labels)
                    obj.delays = str2double(modlo.labels)';
                end

                if ~isempty(modlo.start)
                    if modlo.end > modlo.start
                       nsteps = round((modlo.end - modlo.start)/modlo.step);
                       delays = 0:nsteps;
                       delays = delays .* modlo.step;
                       obj.delays = delays + modlo.start;
                    end
                end

                if ~isempty(strfind(modlo.unit,'NS')) || ~isempty(strfind(modlo.unit,'ns'))
                    obj.delays = obj.delays.* 1000;
                end

                obj.FLIM_type = char(modlo.typeDescription);

            else
            % if no modulo annotation check for Imspector produced ome-tiffs.
                if strcmp(char(r.getFormat()), 'OME-TIFF')
                    parser = loci.formats.tiff.TiffParser(file);
                    service = loci.formats.services.OMEXMLServiceImpl();
                    version = char(service.getOMEXMLVersion(parser.getComment()));

                    if strcmp(version,'2008-02') % Try to load lavision
                        % attempt to extract metadata
                        ras = loci.common.RandomAccessInputStream(file,16);
                        tp = loci.formats.tiff.TiffParser(ras);
                        firstIFD = tp.getFirstIFD();
                        xml = char(firstIFD.getComment());
                        k = strfind(xml,'AxisName="lifetime"');
                        if ~isempty(k)
                            % "autosave" style LaVision ome-tiff so try and handle
                            % accordingly
                            xml = xml(k(1):k(1)+100);    % pull out this section of the xml

                            k = strfind(xml,'PhysicalUnit="');
                            uns = xml(k(1)+14:end);
                            e = strfind(uns,'"') -1;
                            uns = uns(1:e(1));
                            physical_unit = str2double(uns) * 1000;

                            k = strfind(xml,'Steps="');
                            sts = xml(k(1)+7:end);
                            e = strfind(sts,'"') -1;
                            sts = sts(1:e(1));
                            lifetime_steps = str2double(sts);

                            obj.FLIM_type = 'TCSPC';
                            if lifetime_steps == obj.sizeZCT(1)
                                obj.delays = (0:obj.sizeZCT(1)-1).* physical_unit;
                                obj.modulo = 'ModuloAlongZ';
                            end
                            if lifetime_steps == obj.sizeZCT(3)
                                obj.delays = (0:obj.sizeZCT(3)-1).*physical_unit;
                                obj.modulo = 'ModuloAlongT';
                            end

                        else
                            % old-style (not auto-saved) LaVision ome-tiff
                            % Foreced to assume z is actually t
                            if obj.sizeZCT(1) > 1
                                physZ = obj.ome_meta.getPixelsPhysicalSizeZ(0);
                                if ~isempty(physZ)
                                    physSizeZ = physZ.value.doubleValue() .*1000;     % assume this is in ns so convert to ps
                                    obj.delays = (0:sizeZCT(1)-1)*physSizeZ;
                                    obj.modulo = 'ModuloAlongZ';
                                    obj.FLIM_type = 'TCSPC';
                                    obj.sizeZCT = sizeZCT;
                                end
                            end
                        end
                    end
                end
            end

            % get channel_names
            for c = 1:sizeZCT(2)
                obj.chan_info{c} = char(obj.ome_meta.getChannelName(0,c-1));
                if isempty(obj.chan_info{c})
                    obj.chan_info{c} = char(obj.ome_meta.getChannelEmissionWavelength(0,c-1));
                end
                if isempty(obj.chan_info{c})
                    obj.chan_info{c} = ['Channel ' num2str(c-1)];
                end
            end


            if isempty(obj.delays)
                obj.error_message = 'Unable to load! Not time resolved data.';
            end
            
        end
        
        %====================================
        % WELCOME TO THE READER
        %====================================
        
        function target = read(obj, read_selected)
                        
            if verbose
                w = waitbar(0, 'Loading FLIMage....');
                drawnow;
            end

            Zarr = obj.ZCT{1}-1;
            Carr = obj.ZCT{2}-1;
            Tarr = obj.ZCT{3}-1;
                   
            r = obj.bf_reader;
 
            if length(obj.image_series) > 1   % if image_series is a vector indicates a plate
                r.setSeries(obj.image_series(read_selected) - 1);
                read_selected= 1;
            else
                r.setSeries(obj.image_series -1);
            end
               
            %check that image dimensions match those read from first
            %file
            % note the dimension inversion here
            if sizeX ~= r.getSizeY ||sizeY ~= r.getSizeX
                success = false;
                return;
            end
                      
            % Get pixel type
            pixel_type = r.getPixelType();
            bpp = loci.formats.FormatTools.getBytesPerPixel(pixel_type);
            fp = loci.formats.FormatTools.isFloatingPoint(pixel_type);
            sgn = loci.formats.FormatTools.isSigned(pixel_type);
            % assume for now all our data is unsigned (see bfgetPlane for examples of signed)
            little = r.isLittleEndian();
                
            switch bpp
                case 1
                    type = 'uint8';
                case 2
                    type = 'uint16';
                case 4
                    type = 'uint32';
                case 8
                    type = 'uint64';
            end
          
            for zplane = 1:length(Zarr)
                Z = Zarr(zplane);
                
                for c = 1:length(Carr)
                    C = Carr(c);
                    
                    for time = 1:length(Tarr)
                        T = Tarr(time);
                        
                        % check that we are supposed to load this FLIM cube
                        if ctr == read_selected  ||  polarisation_resolved 
                          
                            t = 0;
                            for block = 0:nblocks - 1
                                nplanes = nplanesInBlock(block + 1);
                                
                                switch obj.modulo
                                    case 'ModuloAlongT'
                                        Tt = T * sizet;
                                        if ~sgn
                                            for p = 1:nplanes
                                                % unsigned moduloAlongT
                                                % this is the loop that needs to be
                                                % optimised for speed
                                                index = r.getIndex(Z, C ,Tt + t);
                                                t = t + 1;
                                                rawPlane = r.openBytes(index);
                                                I = loci.common.DataTools.makeDataArray(rawPlane,bpp, fp, little);
                                                I = typecast(I, type);
                                                target(t,pctr,:,:,write_selected) = reshape(I, sizeY, sizeX)';
                                                
                                            end
                                        else  % signed
                                            for p = 1:nplanes
                                                index = r.getIndex(Z, C ,Tt + t);
                                                t = t + 1;
                                                plane = bfGetPlane(r,index + 1);
                                                target(t,pctr,:,:,write_selected) = plane;
                                            end
                                        end
                                        
                                    case 'ModuloAlongZ'
                                        Zt = Z * sizet;
                                        for p = 1:nplanes
                                            index = r.getIndex(Zt + t, C ,T);
                                            t = t + 1;
                                            plane = bfGetPlane(r,index + 1);
                                            target(t,pctr,:,:,write_selected) = plane;
                                        end
                                        
                                    case 'ModuloAlongC'
                                        Ct = C * sizet;
                                        for p = 1:nplanes
                                            index = r.getIndex(Z, Ct + t ,T);
                                            t = t + 1;
                                            plane = bfGetPlane(r,index + 1);
                                            target(t,pctr,:,:,write_selected) = plane;
                                        end
                                        
                                end  % end switch
                                
                                
                                if verbose
                                    totalPlane = totalPlane + nplanes;
                                    waitbar(totalPlane /totalPlanes,w);
                                    drawnow;
                                end
                                
                            end    % end nblocks
                        end     % end if read_selected
                        
                        if polarisation_resolved
                            pctr = pctr + 1;
                        else
                            ctr = ctr + 1;
                        end
                        
                    end
                end     % nchans
            end           

            if verbose
                delete(w);
                drawnow;
            end

            if strcmp('TCSPC',obj.mode)
                
                %Kludge to suppress bright line artefact on RHS in BH .sdt files
                
                if strcmp(obj.ext,'.sdt')  && sizeX > 1 && sizeY > 1
                    target(:,:,:,end,:) = 0;
                end
                
            else    % Not TCSPC
                if min(target(target > 0)) > 32500
                    target = target - 32768;    % clear the sign bit which is set by labview
                end
            end
            
        end
        
    end
    
end