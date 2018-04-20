function writeFfh(filename, data, timepoints, metadata)
% writeFfh  Write FLIM data to a FFH histogram file
%
% filename   : name of the output file
% data       : array of size [n_t n_chan n_y n_x]
% timepoints : array of length n_t with the timepoints in ps
% metadata   : optional structure of metadata fields 

    tag.double  = 0;
    tag.uint64  = 1;
    tag.int64   = 2;
    tag.logical = 4;
    tag.char    = 5;
    tag.date    = 6;
    tag.end     = 7;

    switch class(data)
        case 'double'
            data_type = 'double';
        case 'single'
            data_type = 'float';
        case 'uint16'
            data_type = 'uint16_t';
        otherwise
            error('Unsupported data type, should be double, single or uint16');
    end
    
    f = fopen(filename,'w');

    fwrite(f,hex2dec('C0BE'),'uint32'); % magic string
    fwrite(f,2,'uint32'); % version number
    
    data_pos_location = ftell(f);
    fwrite(f,0,'uint32'); % data position

    if nargin >= 4
        fields = fieldnames(metadata);
        for i=1:length(fields)
            writeTag(fields{i},metadata.(fields{i}));
        end
    end
    
    compressed_data = zlibencode(typecast(data(:),'uint8'));
        
    writeTag('NumTimeBins',int64(size(data,1)));
    writeTag('NumChannels',int64(size(data,2)));
    writeTag('NumY',int64(size(data,3)));
    writeTag('NumX',int64(size(data,4)));
    writeTag('TimeBins',double(timepoints));
    writeTag('DataType',data_type);
    writeTag('CreationDate',char(datetime('now','Format','uuuu-MM-dd''T''HH:mm:ss')));
    writeTag('Compressed',true);
    writeTag('CompressedSize',length(compressed_data));
    writeEndTag();
    
    data_pos = ftell(f);
    
    fseek(f,data_pos_location,-1);    
    fwrite(f,data_pos,'uint32');
    
    fseek(f,data_pos,-1);
    fwrite(f,compressed_data,class(compressed_data));
    
    fclose(f);
    
    function writeTag(name, value)
        value_type = class(value);
        if~isfield(tag,value_type)
            warning(['Tag "' name '" (' value_type ') is not a supported data type, ignoring']);
            return
        end
        
        if length(name) > 255
            name = name(1:255);
        end
        name = [name 0];
        
        type = tag.(value_type);
        if length(value) > 1 && ~ischar(value)
            type = bitor(type,128);
        end
        
        if ischar(value)
            tag_data_length = length(value); % don't want trailing \0
        else
            s=whos('value');
            tag_data_length = [s.bytes];
        end
        
        fwrite(f, length(name), 'uint32');
        fwrite(f, name);
        fwrite(f, type, 'uint16');
        fwrite(f, tag_data_length, 'uint32');
        fwrite(f, value, value_type);

    end
    
    function writeEndTag()
        name = 'EndHeader\0';
        fwrite(f, length(name), 'uint32');
        fwrite(f, name);
        fwrite(f, tag.end, 'uint16');
        fwrite(f, 0, 'uint32');
    end     

end