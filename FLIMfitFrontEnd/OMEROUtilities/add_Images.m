
function ret = add_Images(omero_data_manager, dirpath, filenames, dataset)

        % Copyright (C) 2015 Imperial College London.
        % All rights reserved.
        %
        % This program is free software; you can redistribute it and/or modify
        % it under the terms of the GNU General Public License as published by
        % the Free Software Foundation; either version 2 of the License, or
        % (at your option) any later version.
        %
        % This program is distributed in the hope that it will be useful,
        % but WITHOUT ANY WARRANTY; without even the implied warranty of
        % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        % GNU General Public License for more details.
        %
        % You should have received a copy of the GNU General Public License along
        % with this program; if not, write to the Free Software Foundation, Inc.,
        % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
        %
        % This software tool was developed with support from the UK 
        % Engineering and Physical Sciences Council 
        % through  a studentship from the Institute of Chemical Biology 
        % and The Wellcome Trust through a grant entitled 
        % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
        
       
        
       
        
        if length(filenames) == 0
            return;
        end
        
        
        java.lang.System.clearProperty('java.util.prefs.PreferencesFactory');
         
        % Configuration Object
        config = ome.formats.importer.ImportConfig();
       
        %Set Config params
        config.email.set('');
        config.sendFiles.set(true);
        config.sendReport.set(false);
        config.contOnError.set(false);
        config.debug.set(false);
        
        host = javaObject('java.lang.String',omero_data_manager.logon{1});
        port = javaObject('java.lang.Integer',str2num(omero_data_manager.logon{2}));
        name = javaObject('java.lang.String',omero_data_manager.logon{3});
        passwd = javaObject('java.lang.String',omero_data_manager.logon{4});
        
        config.hostname.set(host);
        config.port.set(port);
        config.username.set(name);
        config.password.set(passwd);
        config.targetClass.set('omero.model.Dataset');
        
        dataID = javaObject('java.lang.Long',dataset.getId.getValue() );
        config.targetId.set(dataID);
        
        %Metadatastore Object
        store = config.createStore();
        store.logVersionInfo(config.getIniVersionNumber());
        reader = ome.formats.importer.OMEROWrapper(config);
        
        uploadRm = ome.formats.importer.transfers.UploadRmFileTransfer;
        library = handle(ome.formats.importer.ImportLibrary(store, reader, uploadRm));
        handler = ome.formats.importer.cli.ErrorHandler(config);
        
        library.addObserver(ome.formats.importer.cli.LoggingImportMonitor());
       
        %Import
        nfiles = length(filenames);
        
        paths = javaArray('java.lang.String',nfiles);
        for p = 1:length(filenames)
            fpath = [dirpath filenames{p}];
            paths(p) = java.lang.String(fpath);   
        end
        
        candidates = ome.formats.importer.ImportCandidates(reader, paths, handler);
        reader.setMetadataOptions(loci.formats.in.DefaultMetadataOptions(loci.formats.in.MetadataLevel.ALL));
        
        containers = candidates.getContainers();

        n = containers.size();
        imageId = [];

        for index=0:n-1
            ic = containers.get(index);
            ic.setTarget(dataset);
            pixels = library.importImage(ic,index,0,n);
            imageId = [imageId ; pixels.get(0).getImage.getId.getValue];
        end
        uploadRm.afterTransfer(handler.errorCount,toJavaList(paths));

end
