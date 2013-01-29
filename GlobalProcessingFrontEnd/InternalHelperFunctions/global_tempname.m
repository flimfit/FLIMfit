function tname = global_tempname

    [path name ext] = fileparts(tempname);
    
    tname = [path filesep 'GPTEMP_' name ext];
    

end