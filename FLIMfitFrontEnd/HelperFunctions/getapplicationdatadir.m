function appDir = getapplicationdatadir(appicationName, doCreate, local)
%GETAPPLICATIONDATADIR   return the application data directory.
%   APPDIR = GETAPPLICATIONDATADIR(APPICATIONNAME, DOCREATE, LOCAL) returns
%   the application's data directory using the registry on windows systems
%   or using Java on non windows systems as a string and creates the
%   directory if missing and requested, i.e. DOCREATE = true.
%   APPICATIONNAME  should be a worldwide unique application name - using
%                   the web domain name as part of the name is a
%                   appropriate method, hierarchical naming is possible cf.
%                   examples
%   DOCREATE        boolean, the application data directory is created if
%                   it is missing and DOCREATE is equal true
%   LOCAL           boolean, if true the local, i.e. the machine related,
%                   application data directory is returned and maybe
%                   created - this argument is ignored on non windows
%                   operating systems
%   GETAPPLICATIONDATADIR throws an error if it is unable to create the
%   application data directory while DOCREATE is being true.
%
%   Examples:
%       getapplicationdatadir('Test', false, false)
%   returns on windows
%       C:\Documents and Settings\MYNAME\Application Data\Test
%   without creating the directory even if it is missing.
%
%       getapplicationdatadir(...
%           fullfile('com','mathworks','companyUnique1',''), true, true)
%   returns on windows
%       C:\Documents and Settings\MYNAME\Local Settings\Application
%       Data\com\mathworks\companyUnique1
%   creating the directory if it is missing.


if ispc
    if local
        allAppDir = winqueryreg('HKEY_CURRENT_USER',...
            ['Software\Microsoft\Windows\CurrentVersion\' ...
            'Explorer\Shell Folders'],'Local AppData');
    else
        allAppDir = winqueryreg('HKEY_CURRENT_USER',...
            ['Software\Microsoft\Windows\CurrentVersion\' ...
            'Explorer\Shell Folders'],'AppData');
    end
    appDir = fullfile(allAppDir, appicationName,[]);
else
    allAppDir = char(java.lang.System.getProperty('user.home'));
    appDir = fullfile(allAppDir, ['~' appicationName],[]);
end
if doCreate
    [success, msg, msgID] = mkdir(appDir); %#ok<NASGU>
    if success ~= 1
        error('getapplicationdatadir:create', ...
            'Unable to create application data directory\n%s\nDetails: %s', ...
            appDir, msg);
    end
end
