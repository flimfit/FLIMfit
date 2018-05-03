
% Script to open the files in a LaVision ome-tiff fileset individually 
% before recombining into a single valid ome-tiff

% Important! Replace path for your own machine
addpath('/Users/imunro/FLIMfit/FLIMfitFrontEnd/BFMatlab');

status = bfCheckJavaPath();
assert(status, ['Missing Bio-Formats library. Either add bioformats_package.jar '...
    'to the static Java path or add it to the Matlab path.']);

filesLoaded = 0;

while(1)
    
    [file, path] = uigetfile(bfGetFileExtensions, 'Choose a LaVision file ');
    id = [path file];
    if isequal(path, 0) || isequal(file, 0), break; end
    r = bfGetReader(id);
    order = r.getDimensionOrder();
    filesLoaded = filesLoaded +1;
    
    r.setSeries(0);
    sizeZCT(1) = r.getSizeZ;
    sizeZCT(2) = r.getSizeC;
    sizeZCT(3) = r.getSizeT;
    
    if filesLoaded == 1   % get timebase from 1st file
        
        referenceSize = sizeZCT;
        
        if strcmp(char(r.getFormat()), 'OME-TIFF')
            % checking for out-of-date SCHEMA
            % 4 x faster than extracting all the xml
            parser = loci.formats.tiff.TiffParser(id);
            service = loci.formats.services.OMEXMLServiceImpl();
            version = char(service.getOMEXMLVersion(parser.getComment()));
            if strcmp(version,'2008-02')
                ras = loci.common.RandomAccessInputStream(id,16);
                tp = loci.formats.tiff.TiffParser(ras);
                firstIFD = tp.getFirstIFD();
                xml = char(firstIFD.getComment());
                dims.sizeZCT = sizeZCT;
                dims = parse_lavision_ome_xml(xml,dims);
            end
        end
    else
        if sizeZCT ~= referenceSize
            disp('Size Mismatch');
            return;
        end
    end
    
    pixelType = r.getPixelType();
    bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
    
    if bpp ~= 2
        disp('Uint16 data only!');
        return;
    end
    
    
    prompt = {'Enter Z:','Enter C:','Enter T:'};
    title = ['Enter Z C T for ' file];
    dimensions = [1 35];
    definput = {'1','1','1'};
    answer = inputdlg(prompt,title,dimensions,definput);
    
    info = imfinfo(id);
    num_images = numel(info);
    
    iZ = str2double(answer{1});
    iC = str2double(answer{2});
    iT = str2double(answer{3});
    tt = ((iT-1) * num_images);
    
    for k = 1:num_images
        target(:,:,iZ,iC,tt+k) = imread(id, k, 'Info', info);
    end
    
end


% NB this line has been found to be crucial
java.lang.System.setProperty('javax.xml.transform.TransformerFactory', 'com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl');

metadata = createMinimalOMEXMLMetadata(target);


modlo = loci.formats.CoreMetadata();

modlo.moduloT.type = loci.formats.FormatTools.LIFETIME;
modlo.moduloT.unit = 'ps';
% replace with 'Gated' if appropriate
modlo.moduloT.typeDescription = 'TCSPC';

modlo.moduloT.start = dims.delays(1);

modlo.moduloT.step = dims.delays(2) - dims.delays(1);
modlo.moduloT.end = dims.delays(end);


OMEXMLService = loci.formats.services.OMEXMLServiceImpl();

OMEXMLService.addModuloAlong(metadata,modlo,0);

filter = {'*.ome.tiff'};
[file, path] = uiputfile(filter,'Select name for valid ome.tiff');

% important to delete old versions before writing.
outputPath = [path file];
if exist(outputPath, 'file') == 2
    delete(outputPath);
end
bfsave(target, outputPath, 'metadata', metadata);




