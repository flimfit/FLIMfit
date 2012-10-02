function type = get_num_type(U)
    type = 'double';
    if     isa(U,'uint16'), type = 'uint16';
    elseif isa(U,'int16'), type = 'int16';
    elseif isa(U,'uint8'), type = 'uint8';
    elseif isa(U,'int8'), type = 'int8';
    elseif isa(U,'uint32'), type = 'uint32';
    elseif isa(U,'int32'), type = 'int32';
    elseif isa(U,'uint64'), type = 'uint64';
    elseif isa(U,'int64'), type = 'int64';
    end
end

