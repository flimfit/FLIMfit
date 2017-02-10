classdef bioformats_reader < base_data_reader
   
    properties
        bf_reader;
        modulo;
        image_series;
    end
    
    methods
       
        function obj = bioformats_reader(filename)
            
            obj.filename = filename;
            obj.init_reader();
            r = obj.bf_reader;
            
            ome_meta = obj.bf_reader.getMetadataStore();
            series_count = obj.bf_reader.getSeriesCount;

            if series_count > 1
                if ome_meta.getPlateCount > 0
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

            obj.data_type = char(ome_meta.getPixelsType(0));            
            assert(any(strcmp(obj.data_type,{'float','uint32','uint16'})));

            
            % check for presence of an Xml modulo Annotation  containing 'lifetime'

            search = {'Z','C','T'};
            modlo = [];
            for i=1:length(search)
                mod = eval(['r.getModulo' search{i} '();']);
                if strfind(lower(char(mod.type)),'lifetime')
                    modlo = mod;
                    obj.modulo = i;
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
                                obj.modulo = 1;
                            end
                            if lifetime_steps == obj.sizeZCT(3)
                                obj.delays = (0:obj.sizeZCT(3)-1).*physical_unit;
                                obj.modulo = 3;
                            end

                        else
                            % old-style (not auto-saved) LaVision ome-tiff
                            % Foreced to assume z is actually t
                            if obj.sizeZCT(1) > 1
                                physZ = ome_meta.getPixelsPhysicalSizeZ(0);
                                if ~isempty(physZ)
                                    physSizeZ = physZ.value.doubleValue() .*1000;     % assume this is in ns so convert to ps
                                    obj.delays = (0:sizeZCT(1)-1)*physSizeZ;
                                    obj.modulo = 1;
                                    obj.FLIM_type = 'TCSPC';
                                    obj.sizeZCT = sizeZCT;
                                end
                            end
                        end
                    end
                end
            end

            obj.sizeZCT(obj.modulo) = obj.sizeZCT(obj.modulo) / length(obj.delays);
            
            % get channel_names
            for c = 1:obj.sizeZCT(2)
                obj.chan_info{c} = char(ome_meta.getChannelName(0,c-1));
                if isempty(obj.chan_info{c})
                    obj.chan_info{c} = char(ome_meta.getChannelEmissionWavelength(0,c-1));
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
        
        function data = read(obj, zct, channels)
                                           
            r = obj.bf_reader;
            
            r.setSeries(0);            
            pixelType = r.getPixelType();
            bpp = javaMethod('getBytesPerPixel', 'loci.formats.FormatTools', pixelType);
            fp = javaMethod('isFloatingPoint', 'loci.formats.FormatTools', pixelType);
            little = r.isLittleEndian();
 
            %{
            TODO
            if length(obj.image_series) > 1   % if image_series is a vector indicates a plate
                r.setSeries(obj.image_series(read_selected) - 1);
                read_selected= 1;
            else
                r.setSeries(obj.image_series -1);
            end
            %}
            
            nt = length(obj.delays);
            data = zeros([nt length(channels) obj.sizeXY], obj.data_type);
            
            t_inc = [0 0 0];
            t_mod = [1 1 1];
            
            t_inc(obj.modulo) = 1;
            t_mod(obj.modulo) = nt;
                                    
            for c = 1:length(channels)
                ch = channels(c);
                
                for t=1:nt
                    idx = (zct - 1) .* t_mod + (t-1) .* t_inc;
                    
                    if zct(2) == -1
                        idx(2) = ch - 1;
                    end
                    
                    index = r.getIndex(idx(1),idx(2),idx(3));
                    rawPlane = r.openBytes(index);
                    I = loci.common.DataTools.makeDataArray(rawPlane, bpp, fp, little);
                    I = typecast(I, obj.data_type);
                    data(t,ch,:,:) = reshape(I, obj.sizeXY(2), obj.sizeXY(1))';
                end
            end           

        end
       
        function init_reader(obj)
            r = loci.formats.ChannelFiller();
            r = loci.formats.ChannelSeparator(r);

            OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
            r.setMetadataStore(OMEXMLService.createOMEXMLMetadata());

            r.setId(obj.filename);
            obj.bf_reader = r;
        end
    end
    
end