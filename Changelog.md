FLIMfit Changelog
=================

v4.5.11
-------
- Add gamma scaling factor for intensity merged images to preferences
- Enable use of a 'library' scatter IRF when generating a t0 map 

v4.5.10
-------
- Enabled OMERO connection in PC version
- Added preferences controlling t0 map generation
- Bug fix: Imagewise fits may not terminate correctly with multithreaded processing
- Bug fix: Crash when fitting globally with a SV IRF

v4.5.9
-------
- Improved loading of .asc files, allow arbitary number of time gates
- Various improvements to OMERO connectivity
- Various UI bug fixes on Mac version

v4.5.8
-------
- Bug fix: Correctly subtract background when smoothing
- Ensure that data is not smoothed when saving magic angle data file
- Allow import of single point data into OMERO
- Various Mac bug fixes

v4.5.6
-------
- Improve loading speed by caching Matlab MCR
- Bug fix: Issues opening segmentation manager in compiled version
- Bug fix: First time point incorrectly identified for timegated data
- Bug fix: Acceptor images may be misindexed if datasets are deselected

v4.5.4
-------
- Invert r_ss colorscale when colourscale inversion is selected
- Various OMERO updates

v4.5.2
-------
- Bug fix: CSV files not correctly loading