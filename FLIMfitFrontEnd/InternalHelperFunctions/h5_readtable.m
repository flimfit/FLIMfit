function tbl = h5_readtable(filename,dataset)

    dat = h5read(filename,dataset);
    tbl = struct2table(dat);