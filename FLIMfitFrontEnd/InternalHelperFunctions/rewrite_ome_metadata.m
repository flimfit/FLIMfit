function rewrite_ome_metadata(folder)
% Set SizeT and SizeC to 1 in Lavision metadata
% Can 'fix' Lavision autosave files with incorrect channel order

    files = dir([folder filesep '*.ome.tif']);

    for i=1:length(files)

        t = Tiff([folder filesep files(i).name],'r+');
        info = getTag(t,'ImageDescription');

        info = regexprep(info,'SizeT="\d+" SizeC="\d+"','SizeT="1" SizeC="1"');

        setTag(t,'ImageDescription',info);
        rewriteDirectory(t)

        disp(['Rewritten: ' files(i).name]);
        
    end