function [delays,t_int,files] = get_delays_from_tif_stack(files)
           
    delays = nan(1,length(files));
    t_int = ones(1,length(files));

    for f = 1:length(files)
        name = files{f};
        tokens = regexp(name,'INT\_(\d+)','tokens');
        if ~isempty(tokens)
            t_int(f) = str2double(tokens{1});
        end
        
        tokens = regexp(name,'(?:^|\s)T\_(\d+)','tokens');
        if ~isempty(tokens)
            delays(f) = str2double(tokens{1});
        elseif length(name) >= 6
            sname = name(end-4:end);      % assume last 6 chars contains delay
            delays(f) = str2double(sname);  
        end
    end
    
    [delays,idx] = sort(delays);
    t_int = t_int(idx);
    files = files(idx);
end