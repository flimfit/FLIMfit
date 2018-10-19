function vx = split_ver(ver)
    % Convert version string into a number
    tk = regexp(ver,'([0-9]+).([0-9]+).([0-9]+)','tokens');
    if ~isempty(tk{1})
        tk = tk{1};
        vx = str2double(tk{1})*1e6 + str2double(tk{2})*1e3 + str2double(tk{3});
    else 
        vx = 0;
    end
end