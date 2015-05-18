
function ret = add_Images(omero_data_manager, dirpath, filenames)

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
        
       
        
        %Import Packages
        import loci.formats.in.DefaultMetadataOptions;
        import loci.formats.in.MetadataLevel;
        import loci.common.*;
        import ome.formats.OMEROMetadataStoreClient;
        import ome.formats.importer.*;
        import ome.formats.importer.ImportConfig;
        import ome.formats.importer.cli.ErrorHandler;
        import ome.formats.importer.cli.LoggingImportMonitor;
        import omero.model.Dataset;
        import omero.model.DatasetI;
        import ome.services.blitz.repo.*;
        import ome.formats.importer.transfers.*;
        import ome.formats.importer.cli.CommandLineImporter;
        import java.util.prefs.*;
        
         if length(filenames) == 0
            return;
        end
        
        %Configuration Object
        config = ImportConfig();
        
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
        
        dataID = javaObject('java.lang.Long',omero_data_manager.dataset.getId().getValue());
        config.targetId.set(dataID);
        
        %Metadatastore Object
        store = config.createStore();
        store.logVersionInfo(config.getIniVersionNumber());
        reader = OMEROWrapper(config);
        
        library = handle(ImportLibrary(store, reader));
        
        handler = ErrorHandler(config);
        library.addObserver(LoggingImportMonitor());
        
        %Import
        for p = 1:length(filenames)
            fpath = [dirpath filenames{p}]
            candidates = ImportCandidates(reader, fpath, handler);
            reader.setMetadataOptions(DefaultMetadataOptions(MetadataLevel.ALL));
            success = library.importCandidates(config, candidates);
            if success == 0
                log = org.apache.commons.logging.LogFactory.getLog('ome.formats.importer.ImportLibrary');
                templog=log.setLevel(0);
            end
        end
  
end
