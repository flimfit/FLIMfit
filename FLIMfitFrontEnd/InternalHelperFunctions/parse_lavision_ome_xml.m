function dims = parse_lavision_ome_xml(xml,dims)

    % The following avoids the need for file I/O:
    inputObject = java.io.StringBufferInputStream(xml);  % or: org.xml.sax.InputSource(java.io.StringReader(xmlString))
    try
        % Parse the input data directly using xmlread's core functionality
        parserFactory = javaMethod('newInstance','javax.xml.parsers.DocumentBuilderFactory');
        p = javaMethod('newDocumentBuilder',parserFactory);
        dom = p.parse(inputObject);
    catch
        % Use xmlread's semi-documented inputObject input feature
        dom = xmlread(inputObject);
    end
    
    function element = get_element(name)
        element = [];
        el = dom.getElementsByTagName(name);
        if el.getLength() > 0
            el = el.item(0);
            attr = el.getAttributes();
            for i=1:attr.getLength()
                attr.item(i-1).getName();
                name = matlab.lang.makeValidName(char(attr.item(i-1).getName()));
                element.(name) = char(attr.item(i-1).getValue());
            end
        end
    end

    if isempty(get_element('ImspectorVersion'))
        throw(MException('FLIMfit:errorProcessingLavision','Not a LaVision file'));
    end
    
    % Detect time gated file
    fast_delay = get_element('Fast_Delay_Box_Is_Active');

    % Detect DC-TCSPC
    dc_tcspc = get_element('DC-TCSPC_Is_Active');

    % Detect instrument mode
    instrument_mode = get_element('InstrumentMode');    
    
    % Gated
    if ~isempty(fast_delay) && str2double(fast_delay.Value) == 1
        
        use_list = get_element('Fast_Delay_Box_T_Use_List_Values');
        if str2double(use_list.Value) == 0
            % not a list of values so use start and stop
            res = get_element('Fast_Delay_Box_T_Resolution');
            nsteps = str2double(res.Value);
            delays = 0:nsteps -1;
            
            len = get_element('Fast_Delay_Box_T_Length');
            step =  str2double(len.Value)/(nsteps -1);
            
            delays = delays .* step;
            
            start = get_element('Fast_Delay_Box_T_StartDelay');
            dims.delays =  delays + str2double(start.Value);
            
        else
            
            delay_values = get_element('Fast_Delay_Box_T_List_of_Values');
            if isempty(delay_values)
                throw(MException('FLIMfit:errorProcessingLavision','Could not find fast delay values'));
            end
            dims.delays = str2num(delay_values.Value);
        end
        dims.FLIM_type = 'Gated';
        
    % TCSPC
    elseif ~isempty(dc_tcspc) && str2double(dc_tcspc.Value) == 1
        lifetime_axis = [];
        for ax=1:3
            axis = get_element(['Axis' num2str(ax-1)]);
            if ~isempty(axis)
                if strcmp(axis.AxisName,'lifetime')
                    axis.Number = ax-1;
                    lifetime_axis = axis;
                end
            end
        end
               
        steps = str2double(lifetime_axis.Steps);
        unit = str2double(lifetime_axis.PhysicalUnit);
        
        dims.delays = (0:(steps-1)) * unit * 1e3; % ns->ps
        dims.FLIM_type = 'TCSPC';        
    
    % Legacy TCSPC
    elseif ~isempty(instrument_mode) && strcmp(instrument_mode.InstrumentMode,'FLIM')  
        pixels = get_element('Pixels');
        steps = dims.sizeZCT(1);
        unit = str2double(pixels.PhysicalSizeZ); 

        dims.delays = (0:(steps-1)) * unit * 1e3; % ns->ps
        dims.FLIM_type = 'TCSPC';        
    
    end
    
    modulo_options = 'ZCT';        
    idx=find(dims.sizeZCT == length(dims.delays),1);
    dims.modulo = ['ModuloAlong' modulo_options(idx)];
end