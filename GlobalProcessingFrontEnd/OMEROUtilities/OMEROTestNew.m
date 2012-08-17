function [ data_cube ] = OMEROtest( ID )
%Try to get some info out of the OMERO server
%   Detailed explanation goes here





client = loadOmero('cell.bioinformatics.ic.ac.uk');
clientAlive = omeroKeepAlive(client);       % don't know about this bit?

session = client.createSession('imunro','13Foulis14')
proxy = session.getContainerService();





image_descriptor = {session ID}

channel =  [1];


[delays, data_cube, name] = OMERO_fetch(image_descriptor, channel);

size(data_cube)

for im = 1:size(data_cube,5)

    figure(im);
    imagesc(squeeze(sum(data_cube(:,:,:,:,im))));
end






client.closeSession();