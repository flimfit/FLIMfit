function delete_from_zip(zipfile, files)
    zip_path = ['jar:file:/' zipfile];
    zip_path = java.lang.String(strrep(zip_path,'\','/'));
        
    zip_properties = java.util.HashMap();
    zip_properties.put(java.lang.String('create'), java.lang.String('false'));
    
    zip_disk = java.net.URI.create(zip_path);
    zipfs = java.nio.file.FileSystems.newFileSystem(zip_disk, zip_properties);
        
    if ~iscell(files)
        files = {files};
    end
    
    for i=1:length(files)   
        a = javaArray('java.lang.String',0);    
        pathInZipfile = zipfs.getPath(java.lang.String(files{i}),a);
        java.nio.file.Files.delete(pathInZipfile);
    end
    
    zipfs.close()
end