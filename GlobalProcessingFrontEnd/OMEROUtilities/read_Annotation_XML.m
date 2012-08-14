function [ ret1 ret2 ] = read_Annotation_XML(session, obj, filename, tagname1, tagname2)

    ret1 = [];
    ret2 = [];

    str = read_Annotation(session, obj, filename);
    
    if isempty(str) 
        return;
    end;
    
    xmlFileName = ['C:\' '\' filename];
    %        
    fid = fopen(xmlFileName,'w');    
        fwrite(fid,str);
    fclose(fid);   
  
    xDoc = xmlread(xmlFileName);
        delete(xmlFileName);
        
    xRoot = xDoc.getDocumentElement;
        schemaURL = char(xRoot.getAttribute('xsi:noNamespaceSchemaLocation'));
    
if ~isempty(tagname1)        
    allListItems = xDoc.getElementsByTagName(tagname1);     
    ret1 = cell(1,allListItems.getLength);
    for i=0:allListItems.getLength-1
        thisListItem = allListItems.item(i);
        childNode = thisListItem.getFirstChild;
        ret1(1,i+1) = childNode.getData;
    end
end
     
if ~isempty(tagname2)            
    allListItems = xDoc.getElementsByTagName(tagname2);     
    ret2 = cell(1,allListItems.getLength);
    for i=0:allListItems.getLength-1
        thisListItem = allListItems.item(i);
        childNode = thisListItem.getFirstChild;
        ret2(1,i+1) = childNode.getData;
    end
end
               
end

