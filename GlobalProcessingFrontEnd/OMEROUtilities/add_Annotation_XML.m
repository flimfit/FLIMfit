function add_Annotation_XML(session, obj, filename, caption, attr, name1, str1, name2, str2, name3, str3)

    docNode = com.mathworks.xml.XMLUtils.createDocument(caption);
    docRootNode = docNode.getDocumentElement;
    docRootNode.setAttribute('attribute',attr);

    if ~isempty(name1) && ~isempty(str1)
    for i = 1:numel(str1),
       thisElement = docNode.createElement(name1);
       thisElement.appendChild(docNode.createTextNode(char(str1{i})));
       docRootNode.appendChild(thisElement);    
    end;
    end;
    
    if ~isempty(name2) && ~isempty(str2)
    for i = 1:numel(str2),
       thisElement = docNode.createElement(name2);
       thisElement.appendChild(docNode.createTextNode(char(str2{i})));
       docRootNode.appendChild(thisElement);    
    end;
    end;
    
    if ~isempty(name3) && ~isempty(str3)
    for i = 1:numel(str3),
       thisElement = docNode.createElement(name3);
       thisElement.appendChild(docNode.createTextNode(char(str3{i})));
       docRootNode.appendChild(thisElement);    
    end;    
    end;
        
    docNode.appendChild(docNode.createComment(['file created ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')]));

    xmlFileName = ['C:\' filename];
    xmlwrite(xmlFileName,docNode);    
    %edit(xmlFileName);    

    namespace = 'IC_PHOTONICS';
    description = ' ';
    %
    sha1 = char('pending');
    file_mime_type = char('application/octet-stream');
    %
    add_Annotation(session, ...
                    obj, ...
                    sha1, ...
                    file_mime_type, ...
                    xmlFileName, ...
                    description, ...
                    namespace);    
    %
    delete(xmlFileName);
end

