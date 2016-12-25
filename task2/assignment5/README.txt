README

from this directory, run as
main('train', 'test')

this requires the open source VLFeat library to be installed.
http://www.vlfeat.org/install-matlab.html

it is loaded on startup via 
run(strcat(matlabroot,'/extern/vlfeat/toolbox/vl_setup'));
thus make sure to have the vlfeat binaries placed in that directory.
