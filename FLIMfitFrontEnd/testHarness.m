
function [ output_args ] = testHarness()
%UNTITLED Summary of this function goes here



    
    % replace path for your own machine 
    addpath('/Users/imunro/FLIMfit/FLIMfitFrontEnd/OMEROMatlab');
  
    loadOmero();
   
    info_jar = fullfile(pwd,[ filesep 'OMEuiUtils' filesep 'OMEuiUtils.jar'])
    javaaddpath(info_jar);
    
    
     client = loadOmero('cell.bioinformatics.ic.ac.uk');
   
    clientAlive = omeroKeepAlive(client);      

    session = client.createSession('????','???');
    
    
    javaclasspath('-dynamic') 
    
    import OMEROUtils.*;
       
    
    
   
    tst = int32(0);
    
    go = 1;
    
    while go == 1
    
        chooser = OMEROUtils.OMEImageChooser(client, tst);
    
        returned = chooser.getSelectedImages()
        
        if returned.length > 0
            go = 0;
        end
        
    end 
     
   
 

    client.closeSession();
    clear chooser
    clear returned
    clear client;
    clear clientAlive;
    clear session;

     unloadOmero;


end
