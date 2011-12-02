function tname = global_tempname

    [path name ext] = fileparts(tempname);
    
    tname = [path '\GPTEMP_' name ext];
    

end