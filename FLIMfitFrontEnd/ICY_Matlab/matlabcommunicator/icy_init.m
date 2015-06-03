
function icy_init()
% icy_init()
%
% Append to the PATH Matlab environment variable all the folders that contain
% Matlab functions in the Icy plugin directory.
%
% To initialize the functions provided by the Matlab<->Icy interaction plugins,
% you have to execute the following commands each time you start Matlab:
% 
% >> addpath('path/to/icy/plugins/ylemontag/matlabcommunicator');
% >> icy_init();
%
% This operation can be done automatically using a startup.m file (please
% consult the Matlab documentation for more details).

% Current path
myself = mfilename('fullpath');

% Text file containing the list of source folders
sep = find(myself=='/', 1, 'last');
communicator_root  = myself(1:sep);
source_folder_file = [communicator_root 'source_folders.txt'];

% Exit now if the source file does not exist
if(~exist(source_folder_file, 'file'))
	return;
end

% Read the file
fid  = fopen(source_folder_file, 'r');
line = fgetl(fid);
while(ischar(line))
	if(exist(line, 'dir'))
		addpath(line);
	end
	line = fgetl(fid);
end
fclose(fid);
