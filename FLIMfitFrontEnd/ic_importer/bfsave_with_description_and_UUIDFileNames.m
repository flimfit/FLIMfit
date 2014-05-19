function bfsave_with_description_and_UUIDFileNames(I, outputPath, description, file_names,   varargin)
% % % % % % % % % % Save a 5D matrix into an OME-TIFF using Bio-Formats library
% % % % % % % % % %
% % % % % % % % % % SYNOPSIS bfsave(I, outputPath)
% % % % % % % % % %          bfsave(I, outputPath, dimensionsOrder)
% % % % % % % % % %
% % % % % % % % % % INPUT:
% % % % % % % % % %       I - a 5D matrix containing the pixels data
% % % % % % % % % %
% % % % % % % % % %       outputPath - a string containing the location of the path where to
% % % % % % % % % %       save the resulting OME-TIFF
% % % % % % % % % %
% % % % % % % % % %       dimensionOrder - optional. A string representing the dimension 
% % % % % % % % % %       order, Default: XYZCT.
% % % % % % % % % %
% % % % % % % % % % OUTPUT

% verify that enough memory is allocated
bfCheckJavaMemory();

% Check for required jars in the Java path
bfCheckJavaPath();

% Not using the inputParser for first argument as it copies data
assert(isnumeric(I), 'First argument must be numeric');

% Input check
ip = inputParser;
ip.addRequired('outputPath', @ischar);
ip.addOptional('dimensionOrder', 'XYZCT', @(x) ismember(x, getDimensionOrders()));
ip.addParamValue('Compression', '',  @(x) ismember(x, getCompressionTypes()));
ip.addParamValue('BigTiff', false , @islogical);
ip.parse(outputPath, varargin{:});

% Create metadata
toInt = @(x) ome.xml.model.primitives.PositiveInteger(java.lang.Integer(x));
OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
metadata = OMEXMLService.createOMEXMLMetadata();
metadata.createRoot();
metadata.setImageID('Image:0', 0);
metadata.setPixelsID('Pixels:0', 0);
metadata.setPixelsBinDataBigEndian(java.lang.Boolean.TRUE, 0, 0);

% Set dimension order
dimensionOrderEnumHandler = ome.xml.model.enums.handlers.DimensionOrderEnumHandler();
dimensionOrder = dimensionOrderEnumHandler.getEnumeration(ip.Results.dimensionOrder);
metadata.setPixelsDimensionOrder(dimensionOrder, 0);

% Set pixels type
pixelTypeEnumHandler = ome.xml.model.enums.handlers.PixelTypeEnumHandler();
if strcmp(class(I), 'single')
    pixelsType = pixelTypeEnumHandler.getEnumeration('float');
else
    pixelsType = pixelTypeEnumHandler.getEnumeration(class(I));
end
metadata.setPixelsType(pixelsType, 0);

% always 'XYZCT'
% Read pixels size from image and set it to the metadat
sizeX = size(I, 2);
sizeY = size(I, 1);
sizeZ = size(I, find(ip.Results.dimensionOrder == 'Z'));
sizeC = size(I, find(ip.Results.dimensionOrder == 'C'));
sizeT = size(I, find(ip.Results.dimensionOrder == 'T'));
metadata.setPixelsSizeX(toInt(sizeX), 0);
metadata.setPixelsSizeY(toInt(sizeY), 0);
metadata.setPixelsSizeZ(toInt(sizeZ), 0);
metadata.setPixelsSizeC(toInt(sizeC), 0);
metadata.setPixelsSizeT(toInt(sizeT), 0);

% IC SPECIFIC - STARTS
dimension = 'Z';
if sizeC > 1
    dimension = 'C';    
elseif sizeT > 1
    dimension = 'T';
end

if ~isempty(description)
    metadata.setImageDescription(sprintf('first line\nsecondline'), 0);
    metadata.setImageDescription(sprintf(description),0);
end

if ~isempty(file_names)
    %
    toPosI = @(x) ome.xml.model.primitives.PositiveInteger(java.lang.Integer(x));
    toNNI = @(x) ome.xml.model.primitives.NonNegativeInteger(java.lang.Integer(x));
    %
    num_files = numel(file_names);
                        %
                        for i = 1:num_files
                                z = 1;
                                c = 1;
                                t = 1;
                                %
                                switch dimension
                                    case 'C'
                                        c = i;
                                    case 'Z'
                                        z = i;
                                    case 'T'
                                        t = i;
                                end
                                %
                                metadata.setUUIDFileName(sprintf(char(file_names{i})),0,i-1);   
                                metadata.setUUIDValue(sprintf(dicomuid),0,i-1);                                   
                                metadata.setTiffDataPlaneCount(toPosI(z),0,i-1);                                
                                % 0-based ?
                                metadata.setTiffDataIFD(toNNI(z-1),0,i-1);
                                metadata.setTiffDataFirstZ(toNNI(z-1),0,i-1);
                                metadata.setTiffDataFirstC(toNNI(c-1),0,i-1);
                                metadata.setTiffDataFirstT(toNNI(t-1),0,i-1);                                                                
                        end                                                                                      
                        %                
end
% IC SPECIFIC - ENDS

% Set channels ID and samples per pixel
for i = 1: sizeC
    metadata.setChannelID(['Channel:0:' num2str(i-1)], 0, i-1);
    metadata.setChannelSamplesPerPixel(toInt(1), 0, i-1);
end

% Here you can edit the function and pass metadata using the adequate set methods, e.g.
% metadata.setPixelsPhysicalSizeX(ome.xml.model.primitives.PositiveFloat(java.lang.Double(.106)),0);
%
% For more information, see http://trac.openmicroscopy.org.uk/ome/wiki/BioFormats-Matlab
%
% For future versions of this function, we plan to support passing metadata as
% parameter/key value pairs

% Create ImageWriter
writer = loci.formats.ImageWriter();
writer.setWriteSequentially(true);
writer.setMetadataRetrieve(metadata);
if ~isempty(ip.Results.Compression)
    writer.setCompression(ip.Results.Compression)
end
if ip.Results.BigTiff
    writer.getWriter(outputPath).setBigTiff(ip.Results.BigTiff)
end
writer.setId(outputPath);

% Load conversion tools for saving planes
switch class(I)
    case {'int8', 'uint8'}
        getBytes = @(x) x(:);
    case {'uint16','int16'}
        getBytes = @(x) loci.common.DataTools.shortsToBytes(x(:), 0);
    case {'uint32','int32'}
        getBytes = @(x) loci.common.DataTools.intsToBytes(x(:), 0);
    case {'single'}
        getBytes = @(x) loci.common.DataTools.floatsToBytes(x(:), 0);
    case 'double'
        getBytes = @(x) loci.common.DataTools.doublesToBytes(x(:), 0);
end

% Save planes to the writer
nPlanes = sizeZ * sizeC * sizeT;
for index = 1 : nPlanes
    [i, j, k] = ind2sub([size(I, 3) size(I, 4) size(I, 5)],index);
    plane = I(:, :, i, j, k)';
    writer.saveBytes(index-1, getBytes(plane));
end

writer.close();

end

function dimensionOrders = getDimensionOrders()

% List all values of DimensionOrder
dimensionOrderValues = ome.xml.model.enums.DimensionOrder.values();
dimensionOrders = cell(numel(dimensionOrderValues), 1);
for i = 1 :numel(dimensionOrderValues),
    dimensionOrders{i} = char(dimensionOrderValues(i).toString());
end
end

function compressionTypes = getCompressionTypes()

% List all values of Compression
writer = loci.formats.ImageWriter();
compressionTypes = arrayfun(@char, writer.getCompressionTypes(),...
    'UniformOutput', false);

end
