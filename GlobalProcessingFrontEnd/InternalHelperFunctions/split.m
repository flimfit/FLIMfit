function l = split(d,s)
    if (strcmp(d,'\'))
        d = '\\';
    end
    l = textscan(s,'%s','delimiter',d);
    l = l{1}';
end
