function h5create_direct(Filename,Dataset,Size,varargin)
%H5CREATE  Create HDF5 dataset.
%   H5CREATE(FILENAME,DATASETNAME,SIZE,Param1,Value1, ...) creates an HDF5
%   dataset with name DATASETNAME and with extents given by SIZE in the
%   file given by FILENAME.  If DATASETNAME is a full path name, all
%   intermediate groups are created if they don't already exist.  If
%   FILENAME does not already exist, it is created.
%
%   Elements of SIZE should be Inf in order to specify an unlimited extent.
%
%   Parameter Value Pairs
%   ---------------------
%       'Datatype'   - May be one of 'double', 'single', 
%                      'uint64', 'int64', 'uint32', 'int32', 'uint16', 
%                      'int16', 'uint8', or 'int8'.  Defaults to 'double'.
%       'ChunkSize'  - Defines chunking layout.  Default is not chunked.
%       'Deflate'    - Defines gzip compression level (0-9).  Default is 
%                      no compression.
%       'FillValue'  - Defines the fill value for numeric datasets.
%       'Fletcher32' - Turns on the Fletcher32 checksum filter.  Default 
%                      value is false.
%       'Shuffle'    - Turns on the Shuffle filter.  Default value is
%                      false.
%
%   Example:  create a fixed-size 100x200 dataset.
%       h5create('myfile.h5','/myDataset1',[100 200]);
%       h5disp('myfile.h5');
%
%   Example:  create a single precision 1000x2000 dataset with a chunk size
%   of 50x80.  Apply the highest level of compression possible.
%       h5create('myfile.h5','/myDataset2',[1000 2000], 'Datatype','single', ...
%                'ChunkSize',[50 80],'Deflate',9);
%       h5disp('myfile.h5');
%
%   Example:  create a two-dimensional dataset that is unlimited along the
%   second extent.
%       h5create('myfile.h5','/myDataset3',[200 Inf],'ChunkSize',[20 20]);
%       h5disp('myfile.h5');
%
%   See also:  h5read, h5write, h5info, h5disp.

%   Copyright 2010 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2011/05/17 02:24:50 $


p = inputParser;
p.addRequired('Filename',@(x)ischar(x));
p.addRequired('Dataset', @(x)ischar(x) & ~isempty(x));  

p.addRequired('Size', @(x) isa(x,'double') && isrow(x) && ~any(x<0));
p.addParamValue('Datatype','double', @(x) ischar(x) && isrow(x) );
p.addParamValue('ChunkSize', [], ...
    @(x) isa(x,'double') && isrow(x) && ~any(x<0));
p.addParamValue('Deflate', [], ...
    @(x) isa(x,'double') && isscalar(x) && (x>=0) && (x<=9));                                      
p.addParamValue('FillValue',[], @(x) isnumeric(x) && isscalar(x));
p.addParamValue('Fletcher32',false, ...
    @(x) (isa(x,'double') || islogical(x)) && isscalar(x));
p.addParamValue('Shuffle',false, ...
    @(x) (isa(x,'double') || islogical(x)) && isscalar(x));

p.parse(Filename,Dataset,Size,varargin{:});
options = validate_options(p.Results);
create_dataset(options);

return


%--------------------------------------------------------------------------
function options = validate_options(options)

% Give a better error message than the low level library would.
if ~isempty(options.Deflate) && isempty(options.ChunkSize)
    error(message('MATLAB:imagesci:h5create:deflateRequiresChunking'));
end

% Setup Extendable.  Either
options.Extendable = false(1,numel(options.Size));
options.Extendable(isinf(options.Size)) = true;
options.Extendable(options.Size == 0) = true;


% Force Shuffle and Fletcher32 options to be logical.
if isnumeric(options.Fletcher32)
    options.Fletcher32 = logical(options.Fletcher32);
end  
if isnumeric(options.Shuffle)
    options.Shuffle = logical(options.Shuffle);
end  
if (options.Fletcher32 || options.Shuffle) && isempty(options.ChunkSize)
     error(message('MATLAB:imagesci:h5create:filterRequiresChunking')); 
end




  
if ~isempty(options.FillValue) && ~strcmp(options.Datatype,class(options.FillValue))
    error(message('MATLAB:imagesci:h5create:datasetFillValueMismatch', class( options.FillValue ), options.Datatype));
end

% Make sure that chunk size does not exceed dataset size.  After that,
% reset any Infs to zero before continuing.  The initial size of an
% unlimited extent must be zero to begin with.

if ~isempty(options.ChunkSize)
    if numel(options.ChunkSize) ~= numel(options.Size)
        error(message('MATLAB:imagesci:h5create:chunkSizeDatasetSizeMismatch'));
    end
    if any((options.ChunkSize - options.Size) > 0)
        error(message('MATLAB:imagesci:h5create:chunkSizeLargerThanDataset'));
    end
end
options.Size(isinf(options.Size)) = 0;

if ( ~isempty(options.Extendable) ) 
    if any(options.Extendable) && isempty(options.ChunkSize)
        error(message('MATLAB:imagesci:h5create:extendibleRequiresChunking'));   
    end
end


% If the file exists, check that it is an HDF5 file.
if exist(options.Filename,'file')
    fid = fopen(options.Filename);
    fullpath = fopen(fid);
    fclose(fid);
    if ~H5F.is_hdf5(fullpath)
        error(message('MATLAB:imagesci:h5create:notHDF5', options.Filename));
    end
    options.Filename = fullpath;
end

if options.Dataset(1) ~= '/'
    error(message('MATLAB:imagesci:h5create:notFullPathName'));
end

%--------------------------------------------------------------------------
function create_dataset(options)

if exist(options.Filename,'file')
    fid = H5F.open(options.Filename,'H5F_ACC_RDWR','H5P_DEFAULT');
    file_was_created = false;
else
    fid = H5F.create(options.Filename,'H5F_ACC_TRUNC','H5P_DEFAULT', ...
        'H5P_DEFAULT');
    file_was_created = true;
end

% Does the dataset already exist?
%try
%    dset = H5D.open(fid, options.Dataset);
%    H5D.close(dset);
%    error(message('MATLAB:imagesci:h5create:datasetAlreadyExists', options.Dataset));
%catch me
%    if strcmp(me.identifier,'MATLAB:imagesci:h5create:datasetAlreadyExists')
%        rethrow(me)
%    end
%end

try
    
    switch(options.Datatype)
        case 'double'
            datatype = 'H5T_NATIVE_DOUBLE';
        case 'single'
            datatype = 'H5T_NATIVE_FLOAT';
        case 'uint64'
            datatype = 'H5T_NATIVE_UINT64';
        case 'int64'
            datatype = 'H5T_NATIVE_INT64';
        case 'uint32'
            datatype = 'H5T_NATIVE_UINT';
        case 'int32'
            datatype = 'H5T_NATIVE_INT';
        case 'uint16'
            datatype = 'H5T_NATIVE_USHORT';
        case 'int16'
            datatype = 'H5T_NATIVE_SHORT';
        case 'uint8'
            datatype = 'H5T_NATIVE_UCHAR';
        case 'int8'
            datatype = 'H5T_NATIVE_CHAR';
        otherwise
            error(message('MATLAB:imagesci:h5create:unrecognizedDatatypeString', options.Datatype));
    end
    
    
    % Set the maxdims parameter to take into account any extendable
    % dimensions.
    maxdims = options.Size;
    if any(options.Extendable)
        unlimited = H5ML.get_constant_value('H5S_UNLIMITED');
        maxdims(options.Extendable) = unlimited;
    end
    
    % Create the dataspace.
    space_id = H5S.create_simple(numel(options.Size), ...
            fliplr(options.Size), fliplr(maxdims));
    cspace_id = onCleanup(@()H5S.close(space_id));
    
    
    % If the dataset is buried a few groups down, then we want to create 
    % all intermediate groups.
    lcpl = H5P.create('H5P_LINK_CREATE');
    clcpl = onCleanup(@()H5P.close(lcpl));
    H5P.set_create_intermediate_group(lcpl,1);
    
    
    dcpl = construct_dataset_creation_property_list(options);
    cdcpl = onCleanup(@()H5P.close(dcpl));
    dapl = 'H5P_DEFAULT';
    
    dset_id = H5D.create(fid,options.Dataset,datatype,space_id,lcpl,dcpl,dapl);
    
catch me
    H5F.close(fid);
    if file_was_created
        delete(options.Filename);
    end
    rethrow(me);       
end

H5D.close(dset_id);
return

%--------------------------------------------------------------------------
function dcpl = construct_dataset_creation_property_list(options)
% Setup the DCPL - dataset create property list.


dcpl = H5P.create('H5P_DATASET_CREATE');

% Modify the dataset creation property list for the shuffle filter if
% so ordered.
if options.Shuffle
    H5P.set_shuffle(dcpl);
end

% Modify the dataset creation property list for possible chunking and
% deflation.
if ~isempty(options.ChunkSize)
    H5P.set_chunk(dcpl,fliplr(options.ChunkSize));
end
if ~isempty(options.Deflate)
    H5P.set_deflate(dcpl,options.Deflate);
end

% Modify the dataset creation property list for a possible fill value.
if ~isempty(options.FillValue)
    switch(options.Datatype)
        case 'double'
            filltype = 'H5T_NATIVE_DOUBLE';
            fv = double(options.FillValue);
        case 'single'
            filltype = 'H5T_NATIVE_FLOAT';
            fv = single(options.FillValue);
        case 'uint64'
            filltype = 'H5T_NATIVE_UINT64';
            fv = uint64(options.FillValue);
        case 'int64'
            filltype = 'H5T_NATIVE_INT64';
            fv = int64(options.FillValue);
        case 'uint32'
            filltype = 'H5T_NATIVE_UINT';
            fv = uint32(options.FillValue);
        case 'int32'
            filltype = 'H5T_NATIVE_INT';
            fv = int32(options.FillValue);
        case 'uint16'
            filltype = 'H5T_NATIVE_USHORT';
            fv = uint16(options.FillValue);
        case 'int16'
            filltype = 'H5T_NATIVE_SHORT';
            fv = int16(options.FillValue);
        case 'uint8'
            filltype = 'H5T_NATIVE_UCHAR';
            fv = uint8(options.FillValue);
        case 'int8'
            filltype = 'H5T_NATIVE_CHAR';
            fv = int8(options.FillValue);
        otherwise
            H5P.close(dcpl);
            error(message('MATLAB:imagesci:h5create:badFillValueType'));
    end
    H5P.set_alloc_time(dcpl,'H5D_ALLOC_TIME_EARLY');
    H5P.set_fill_value(dcpl,filltype,fv);
end

% Modify the dataset creation property list for the fletcher32 filter if
% so ordered.
if options.Fletcher32
    H5P.set_fletcher32(dcpl);
end


            
