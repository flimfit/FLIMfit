function l = split(d,s)
    l = textscan(s,'%s','delimiter',d);
    l = l{1}';
end
