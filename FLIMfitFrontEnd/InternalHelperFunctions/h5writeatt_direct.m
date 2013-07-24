function h5writeatt_direct(filename,location,attname,attvalue)
%H5WRITEATT  Write HDF5 attribute.
%   H5WRITEATT(FILENAME,LOCATION,ATTNAME,ATTVALUE) writes the attribute
%   named ATTNAME with the value ATTVALUE to the HDF5 file FILENAME.  The
%   parent object LOCATION can be either a group or variable.  LOCATION
%   must be a complete pathname.
%
%   The specified attribute will be created if it does not already exist.  
%   If the specified attribute already exists but does not have a datatype
%   or dataspace consistent with ATTVALUE, the attribute will be deleted 
%   and recreated.
%
%   String attributes will be created with a scalar dataspace.
%
%   Example:  Create a root group attribute whose value is the current
%   time.
%       srcFile = fullfile(matlabroot,'toolbox','matlab','demos','example.h5');
%       copyfile(srcFile,'myfile.h5');
%       fileattrib('myfile.h5','+w');
%       h5writeatt('myfile.h5','/','creation_date',datestr(now));
%
%   Example:  Create a double precision data set attribute.
%       srcFile = fullfile(matlabroot,'toolbox','matlab','demos','example.h5');
%       copyfile(srcFile,'myfile.h5');
%       fileattrib('myfile.h5','+w');
%       attData = [0 1 2 3];
%       h5writeatt('myfile.h5','/g4/world','attr',attData);
%       h5disp('myfile.h5','/g4/world');
%
%   See also H5READATT, H5DISP.

%   Copyright 2010 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2011/05/17 02:24:57 $

p = inputParser;
p.addRequired('filename',@(x)ischar(x) & exist(x,'file'));
p.addRequired('location',@(x)ischar(x));
p.addRequired('attname',@(x)ischar(x));
p.addRequired('attvalue',@(x)true);
p.parse(filename,location,attname,attvalue);

hfile = p.Results.filename;
location = p.Results.location;
attname = p.Results.attname;
attvalue = p.Results.attvalue;

if location(1) ~= '/'
    error(message('MATLAB:imagesci:h5writeatt:notFullPathName'));
end
    
try
    fileId = H5F.open(filename,'H5F_ACC_RDWR','H5P_DEFAULT');
    cf     = onCleanup(@()H5F.close(fileId));
catch me
    switch me.identifier
        case 'MATLAB:imagesci:hdf5lib:libraryError'
            % The file exists, but we cannot open it.  Most likely it is not a
            % valid HDF5 file.
            error(message('MATLAB:imagesci:h5writeatt:invalidFile', hfile));
            
        otherwise
            rethrow(me);
    end
end
try
    objId  = H5O.open(fileId,location,'H5P_DEFAULT');
    co     = onCleanup(@()H5O.close(objId));
catch me
    switch me.identifier
        case 'MATLAB:imagesci:hdf5lib:libraryError'
            error(message('MATLAB:imagesci:h5writeatt:invalidLocation', location));         
            
        otherwise
            rethrow(me);
    end
end

dataspaceId = createDataspaceId(attvalue);
cdsp        = onCleanup(@()H5S.close(dataspaceId));
datatypeId  = createDatatypeId(attvalue);
cdt         = onCleanup(@()H5T.close(datatypeId));
acpl        = H5P.create('H5P_ATTRIBUTE_CREATE');
cacpl       = onCleanup(@()H5P.close(acpl));

% If the attribute already exists, open it.  If it does not exist, create
% it.
attrId = H5A.create(objId,attname,datatypeId,dataspaceId,acpl);


% Is the datatype equivalent?  Is the dataspace equivalent?
atype = H5A.get_type(attrId);  catype = onCleanup(@()H5T.close(atype));
space = H5A.get_space(attrId); cspace = onCleanup(@()H5S.close(space));

[~,dims] = H5S.get_simple_extent_dims(space);
if ( ~H5T.equal(atype,datatypeId) ) || (prod(dims) ~= numel(attvalue))
    % Must delete the attribute and recreate it.
    H5A.close(attrId);
    H5A.delete(objId,attname);
    attrId = H5A.create(objId,attname,datatypeId,dataspaceId,acpl);
end
cattrId = onCleanup(@()H5A.close(attrId));

H5A.write(attrId,datatypeId,attvalue);







%--------------------------------------------------------------------------
function dataspace_id = createDataspaceId(attvalue)
% Setup the dataspace ID.  This just depends on how many elements the 
% attribute actually has.

if isempty(attvalue)
    dataspace_id = H5S.create('H5S_NULL');
    return;
elseif ischar(attvalue)
    if isrow(attvalue)
        dataspace_id = H5S.create('H5S_SCALAR');
        return
    else
        error(message('MATLAB:imagesci:h5writeatt:badStringSize'));
    end
else
    if ( ndims(attvalue) == 2 ) && ( any(size(attvalue) ==1) )
        rank = 1;
        dims = numel(attvalue);
    else
        % attribute is a "real" 2D value.		
        rank = ndims(attvalue);
	    dims = fliplr(size(attvalue));
    end
end
dataspace_id = H5S.create_simple(rank,dims,dims);



%--------------------------------------------------------------------------
function datatype_id = createDatatypeId ( attvalue )
% We need to choose an appropriate HDF5 datatype based upon the attribute
% data.
switch class(attvalue)
	case 'double'
	    datatype_id = H5T.copy('H5T_NATIVE_DOUBLE');
	case 'single'
	    datatype_id = H5T.copy('H5T_NATIVE_FLOAT');
	case 'int64'
	    datatype_id = H5T.copy('H5T_NATIVE_LLONG');
	case 'uint64'
	    datatype_id = H5T.copy('H5T_NATIVE_ULLONG');
	case 'int32'
	    datatype_id = H5T.copy('H5T_NATIVE_INT');
	case 'uint32'
	    datatype_id = H5T.copy('H5T_NATIVE_UINT');
	case 'int16'
	    datatype_id = H5T.copy('H5T_NATIVE_SHORT');
	case 'uint16'
	    datatype_id = H5T.copy('H5T_NATIVE_USHORT');
	case 'int8'
	    datatype_id = H5T.copy('H5T_NATIVE_SCHAR');
	case 'uint8'
	    datatype_id = H5T.copy('H5T_NATIVE_UCHAR');
	case 'char'
	    datatype_id = H5T.copy('H5T_C_S1');
        if ~isempty(attvalue)
            % Don't do this when working with empty strings.
            H5T.set_size(datatype_id,numel(attvalue));
        end
		H5T.set_strpad(datatype_id,'H5T_STR_NULLTERM');
    otherwise
		error(message('MATLAB:imagesci:h5writeatt:unsupportedAttributeDatatype', class( attvalue )));
end
return

