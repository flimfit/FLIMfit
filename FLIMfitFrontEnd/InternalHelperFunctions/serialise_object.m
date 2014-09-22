function DOMnode = serialise_object(obj,file,name)

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

    % Author : Sean Warren
    
   
    if isstruct(obj)
        if nargin < 3
            name = 'data';
        end
        flds = fieldnames(obj); 
    else        
        flds = {};
        mc = metaclass(obj);
        mp = mc.Properties;
        name = mc.Name;
        for i=1:length(mp)
            if mp{i}.Transient == false && mp{i}.Dependent == false && mp{i}.Constant == false
                flds{end+1} = mp{i}.Name;
            end
        end
            
    end

    
    try
        % Create a sample XML document.
        docNode = com.mathworks.xml.XMLUtils.createDocument(name);
        docRootNode = docNode.getDocumentElement;
        for i=1:length(flds)
            val = obj.(flds{i});
            if ~isstruct(val) && ~iscell(val) && ~isjava(val)                
                thisElement = docNode.createElement(flds{i}); 

                if all(size(val)>1)% check for a multidimensional matrix
                    str = serialize(val);
                    str = base64encode(str,'java',true);
                    thisElement.setAttribute('encoded','true');
                else
                    str = mat2str(val);
                end

                thisElement.appendChild(docNode.createTextNode(str));
                docRootNode.appendChild(thisElement);
            end
        end
    
        if isempty(file)
            % if no file specified simply return the DOM
            DOMnode = xmlwrite(file,docNode);
        else
            xmlwrite(file,docNode);
        end
        
    catch e
        warning('GlobalAnalysis:CouldNotWriteFile','Could not write serialised file');
    end
    
end