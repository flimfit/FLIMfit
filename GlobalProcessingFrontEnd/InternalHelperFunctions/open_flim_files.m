%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% THIS FUNCTION IS DEPRECATED!
% PLEASE USE LOAD_FLIM_FILE INSTEAD
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[delays,ImData,tcspc,PathName,channel] = open_flim_files(prompt,FileName,channel)

%Opens a set if .tiffs, .pngs or a .sdt file into 
%into a 3d image of dimensions [num_time_points,height,width]

tcspc = 0;              % default is 'not tcspc'
current = pwd;          % find current directory

if (nargin < 3)
    channel = -1;
end

if (nargin < 2 || isempty(FileName))
    %selects the folder and a file
    %directory = uigetdir;
    [FileName,PathName] = uigetfile('*.*',prompt);

    % Check that user didn't cancel
    if (FileName == 0)
        return
    end

    [~,name,ext] = fileparts(FileName);
    FileName = [PathName FileName];
else
    [PathName,name,ext] = fileparts(FileName);
end


%cd(PathName);
switch ext
    
    % .tif files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '.tif'
        dirStruct = dir(PathName);
        siz = size(dirStruct);
        noOfFiles = siz(1);
        
        success = 1;
        for f = 3:noOfFiles
            filename = [PathName filesep dirStruct(f).name];
            [path,name,ext] = fileparts(filename);
            switch ext
                case '.tif'
                    name = name(end-4:end);      %last 6 chars contains delay 
                    tmp = str2double(name);
                    delays(success) = tmp;
                    try
                        ImData(success,:,:) = imread(filename,'tif');
                        success = success + 1;
                    catch error
			            errordlg(error,'File Type Error','modal')
                    end
            end
            
        end
        
        
%        ImData = double(ImData);
        
        if min(min(min(ImData))) > 32500
            ImData = ImData - 32768;    % clear the sign bit which is set by labview
        end
        
        
     % .png files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
     case '.png'
         
         % copy the first bit of the filename containing the frame
        frameid = 'xxxxx';
        for i = 1:5
            frameid(i) = name(i);
        end
        dirStruct = dir(PathName);
        siz = size(dirStruct);
        noOfFiles = siz(1);

        noOfValidFiles = 0;
        success = 1;
        for f = 3:noOfFiles
    
            filename = dirStruct(f).name;
            [path,name,ext,ver] = fileparts(filename);
            switch ext
                case '.png'
                    for i = 1:5
                        frameid2(i) = name(i);
                    end
                    if frameid2 == frameid
                        noOfValidFiles = noOfValidFiles+1;
                        % extract the part of the name containing the delay
                        for i = 9:13
                            delid(i) = name(i);
                        end
                        tmp = str2num(delid);
                        delays(noOfValidFiles) = tmp;
                        try
                            ImData(success,:,:) = OpenPng(filename);
                            success = success + 1;
                        catch
			                errordlg(lasterr,'File Type Error','modal')
                        end
                    end
            end
            
        end
        
     % .sdt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
     case '.sdt'
    
         
         [ImData, delays]=loadBHfileusingmeasDescBlock(FileName,channel);
         %[ImData delays]=loadBHfileWorking(FileName);
         tcspc = 1;
         %siz = size(ImData);
         %dataPoints = siz(1);
         % discard last few points where TAC goes non-linear
         %ImData = ImData(1:dataPoints-7,:,:);
         %delays = delays(1:dataPoints-7);
     
         
     % .asc files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
     case '.asc'
         tcspc = 1;
         
         dataUnShaped = dlmread(FileName);
         siz = size(dataUnShaped);
         if length(siz) == 2      % if  data is not 3d
             if siz(1) == 2     % looks like this includes delays
                 step = dataUnShaped(1,3)/dataUnShaped(1,2);
                 if step > 1.99 && step < 2.01
                     dataUnShaped = squeeze(dataUnShaped(2,:));   % discard delays
                 else
                     dataUnShaped = squeeze(dataUnShaped(1,:));
                 end
             end
             if siz(2) == 2     % looks like this includes delays
                 step = dataUnShaped(3,1)/dataUnShaped(2,1);
                 if step > 1.99 && step < 2.01
                     dataUnShaped = squeeze(dataUnShaped(:,2));   % discard delays
                 else
                     dataUnShaped =  squeeze(dataUnShaped(:,1));
                 end
             end
         end
         
         
         res = sqrt(size(dataUnShaped,1)/64)
         if res >= 1 
            ImData = reshape(dataUnShaped, 64, res, res);
            delays = (0:63)*12500.0/64;
         else
             ImData = dataUnShaped;
            delays = (0:length(ImData)-1)*12500.0/64;
         end
         
         
             
      % .txt files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case '.txt'
         tcspc = 1;
         
         % check if we're reading a TRFA file
         fid = fopen(FileName);
         first_line = fgetl(fid);
         fclose(fid);
         
         if strcmp(first_line,'TRFA_IC_1.0')
             
         else

             fid = fopen(FileName);
             
             header_lines = 0;
             textl = fgetl(fid);
             while ~isempty(textl)
                 first = sscanf(textl,'%f\t');
                 if isempty(first)
                     header_lines = header_lines + 1;
                     textl = fgetl(fid);
                 else 
                     textl = [];
                 end                 
             end
             
             fclose(fid);
             
             
             ir = dlmread(FileName,'\t',header_lines,0);
             
             noOfChannels = size(ir,2);

             switch noOfChannels
                case 1      % only one column of data so assume 12500ps
                     ImData(:,1,1) = ir;

                     step = 12500./(size(ir,1)-1); % kludge tp make lengths match
                    delays = 0:step:12500;

                case 2      % 2 column data (includes delays)
                    ImData(:,1,1) = ir(:,2);
                    delays(1,:) = ir(:,1);

                 otherwise

                    if (channel == -1)
                        dlgTitle = 'Select channel';
                        prompt = {'Channel '};
                        defaultvalues = {'1'};
                        chann = 0;
                        numLines = 1;
                        while (chann < 1) || (chann > noOfChannels -1)
                            inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                            chann = uint32(str2num(inputdata{1}));
                        end
                    else
                        chann = channel;
                    end

                    % first column is delays so channel i is column 2 etc
                    for c=1:length(chann);
                        ImData(:,c,1,1) = ir(:,chann(c) + 1); %#ok
                    end
                    
                    delays(1,:) = ir(:,1);
             end

             ImData = ImData(~isnan(delays),:,:,:);
             delays = delays(~isnan(delays));

             if max(delays) < 1000
                delays = delays * 1000;
             end
         end
         
    case '.irf'        % Yet another F%^^ing format (for Labview this time)
        tcspc = 1;    
        ir = load([FileName]);
        
        ImData(:,1,1) = ir(:,2);    
        delays(1,:) = ir(:,1);  %.*1000;
                
            
         
             
           
	otherwise 
		
		errordlg('Not a .recognised file type!','File Error');
end
    