        function ret = is_Dataset_name_unique(project,new_dataset_name)                                                                              
                ret = true;
                datasetsList = project.linkedDatasetList;
                for i = 0:datasetsList.size()-1,
                    d = datasetsList.get(i);
                    dName = char(java.lang.String(d.getName().getValue()));                                         
                    % 
                    if strcmp(new_dataset_name,dName)
                        ret = false;
                        return;
                    end;                    
                end;
        end  
        