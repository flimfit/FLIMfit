function node = create_ModuloAlongDOM(delays, namespace, modulo, FLIM_type)

% creates a DOM suitable for use in a ModuloAlong XmlAnnotation
% node = create_ModuloAlongDom(delays,modulo, FLIM_type)
% creates a new DOM using the time delays & modulo specified
%



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
        

        node = false;
        
       
        if nargin < 3
            modulo = 'ModuloAlongT';        % default for time-resolved data
        end
        
        if isempty(delays)
            return;
        end;
                                    
       if isempty(namespace)
           namespace = 'http://www.openmicroscopy.org/Schemas/Additions/2011-09';
       end
        
       % ModuloAlong annotation
       node = com.mathworks.xml.XMLUtils.createDocument('Modulo');
       Modulo = node.getDocumentElement;
     
       Modulo.setAttribute('namespace',namespace);

     
       ModuloAlong = node.createElement(modulo);                                
                                        
       ModuloAlong.setAttribute('Type','lifetime');
       ModuloAlong.setAttribute('Unit','ps');
       
       if strfind('Gated',FLIM_type)
           
           for i=1:length(delays)
                thisElement = node.createElement('Label'); 
                thisElement.appendChild(node.createTextNode(num2str(delays(i))));
               ModuloAlong.appendChild(thisElement);
           end
       
       else
           
           ModuloAlong.setAttribute('Start',num2str(delays(1)));                        
           ModuloAlong.setAttribute('Step',num2str(delays(2) - delays(1)));
           ModuloAlong.setAttribute('End',num2str(delays(end)));
       end
                                       
                                       
      Modulo.appendChild(ModuloAlong);  
      
end
