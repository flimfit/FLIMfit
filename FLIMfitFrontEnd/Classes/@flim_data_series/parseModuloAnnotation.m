function ret = parse_modulo_annotation(obj, s, sizeZCT, physSizeZ)
    % parses the string returned form a 'Lifetime' modulo annotation
    % to find Modulo & delays


    % Copyright (C) 2013 Imperial College London.
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

    ret = [];
    
    if ~isempty(s)      % found correct ModuloAlong XmlAnnotation
    
        
        [parseResult,~] = xmlreadstring(s);
        tree = xml_read(parseResult);
        
        
             
        modlo = [];
        if isfield(tree,'ModuloAlongC')
            modlo = tree.ModuloAlongC;
            ret.modulo = 'ModuloAlongC';
        elseif isfield(tree,'ModuloAlongT')
            modlo = tree.ModuloAlongT;
            ret.modulo = 'ModuloAlongT';
        elseif  isfield(tree,'ModuloAlongZ')
            modlo = tree.ModuloAlongZ;
            ret.modulo = 'ModuloAlongZ';
        end;  
        
        
        if isempty(modlo)       % should never happen
            ret = [];
            return;
        end
        
        if isfield(modlo.ATTRIBUTE,'Type')
            if isempty(strfind(modlo.ATTRIBUTE.Type,'lifetime'))
                ret = [];
                return;
            end
        end
        
            
        
        if isfield(modlo.ATTRIBUTE,'Start')
            start = modlo.ATTRIBUTE.Start;
            step = modlo.ATTRIBUTE.Step;
            e = modlo.ATTRIBUTE.End; 
            nsteps = round((e - start)/step);
            delays = 0:nsteps;
            delays = delays .* step;
            ret.delays = delays + start;
           
            
        else
            if isnumeric(modlo.Label)
                ret.delays = modlo.Label;
            else
                ret.delays = cell2mat(modlo.Label);
            end
        end
        
        if isfield(modlo.ATTRIBUTE,'Unit')
            if ~isempty(strfind(modlo.ATTRIBUTE.Unit,'NS')) || ~isempty(strfind(modlo.ATTRIBUTE.Unit,'ns'))
                ret.delays = ret.delays.* 1000;
            end
        end
       
        
        % Deprecated. Replaced by "TypeDescription" To be removed when safe.
        if isfield(modlo.ATTRIBUTE,'Description')        
            ret.FLIM_type = modlo.ATTRIBUTE.Description;
        end
        
         if isfield(modlo.ATTRIBUTE,'TypeDescription')        
            ret.FLIM_type = modlo.ATTRIBUTE.TypeDescription;
         end
        
    else    % no modulo Annotation 
        
        
        
        % no Modulo XmlAnnotation. Forced to treat it as a
        % LaVision ome.tif
        
        if ~isempty(physSizeZ) 
            if 1 == sizeZCT(2) && 1 == sizeZCT(3) && sizeZCT(1) > 1
                physSizeZ = physSizeZ.*1000;     % assume this is in ns so convert to ps
                ret.delays = (0:sizeZCT(1)-1)*physSizeZ;
                ret.modulo = 'ModuloAlongZ';
                ret.FLIM_type = 'TCSPC';
            end
        end
    end
                        
        
   if ~isempty(ret)
        
       
        % validity check
        % crude  test for nonsense in the Annotation
        sizet = length(ret.delays);
        switch ret.modulo
            case 'ModuloAlongZ'
                SizeZ = sizeZCT(1);
                nZplanes = floor(SizeZ/sizet);
                if nZplanes * sizet ~= SizeZ
                    ret = [];   
                end
            case 'ModuloAlongC'
                SizeC = sizeZCT(2);
                nchannels = floor(SizeC/sizet);
                if nchannels * sizet ~= SizeC
                    ret = [];   
                end
            case 'ModuloAlongT'
                SizeT = sizeZCT(3);
                nTpoints = floor(SizeT/sizet);
                if nTpoints * sizet ~= SizeT
                    ret = [];   
                end
            
        end
        
        ret.sizeZCT = sizeZCT;
   end
   
   
       
    
    
    
                  
             

        
    
    
  