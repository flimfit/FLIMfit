function process_bioformats(obj)

    obj.ome_meta = obj.bf_reader.getMetadataStore();
    series_count = obj.bf_reader.getSeriesCount;

    if series_count > 1
        if obj.ome_meta.getPlateCount > 0
            % plate! so check imageSeries has been setup or throw error
            if obj.imageSeries == -1 || length(obj.imageSeries) ~= length(obj.file_names)
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

    obj.bf_reader.setSeries(obj.imageSeries(1) - 1);

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