function serialise_object(obj,file)

    mc = metaclass(obj);
    mp = mc.Properties;

    % Create a sample XML document.
    docNode = com.mathworks.xml.XMLUtils.createDocument(mc.Name);
    docRootNode = docNode.getDocumentElement;
    for i=1:length(mp)
        if mp{i}.Transient == false && mp{i}.Dependent == false && mp{i}.Constant == false
            val = obj.(mp{i}.Name);
            str = mat2str(val);

            thisElement = docNode.createElement(mp{i}.Name); 
            thisElement.appendChild(docNode.createTextNode(str));
            docRootNode.appendChild(thisElement);
        end
    end
    try
        xmlwrite(file,docNode);
    catch e
        warning('GlobalAnalysis:CouldNotWriteFile','Could not write serialised file');
    end
end