function serialise_object(obj,file,name)

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

    
    %try
        % Create a sample XML document.
        docNode = com.mathworks.xml.XMLUtils.createDocument(name);
        docRootNode = docNode.getDocumentElement;
        for i=1:length(flds)
            val = obj.(flds{i});

            thisElement = docNode.createElement(flds{i}); 

            if all(size(val)>1) % check for a multidimensional matrix
                str = serialize(val);
                str = base64encode(str,'java',true);
                thisElement.setAttribute('encoded','true');
            else
                str = mat2str(val);
            end

            thisElement.appendChild(docNode.createTextNode(str));
            docRootNode.appendChild(thisElement);
        end
    
        xmlwrite(file,docNode);
    %catch e
    %    warning('GlobalAnalysis:CouldNotWriteFile','Could not write serialised file');
    %end
end