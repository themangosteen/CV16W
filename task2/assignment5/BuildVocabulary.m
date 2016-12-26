function [vocabulary] = BuildVocabulary(imgDirPath, numClusters)
% Construct the vocabulary (bag) of visual words (cluster centers in SIFT feature space)
% by clustering SIFT features taken from all imgs via k-means
% (we cluster 128D features not their 2D sample positions!!)
% and using the cluster centers in the 128 dimensional 
% SIFT feature space (128 magnitudes whose orientation is ignored) as words.
% 
% INPUT
% imgDirPath  ... image source directory, each class of images should have its own subdir
%                 images must be grayscale JPG
% numClusters ... number of k-means cluster centers (= number of words in vocabulary)
%
% OUTPUT
% vocabulary ... visual words, i.e. cluster centers in SIFT feature space
%                each columns is a 128 elem SIFT feature vector

%% Gather list of SIFT features from all images
disp('Gathering SIFT features from all images...');

imgCount = 0; % total number of images used
siftFeatureDescriptors = []; % each column will be one 128 elem SIFT feature vector

d = dir(imgDirPath);
subdirs = {d([d(:).isdir]).name}; % subdirs (one for each class of images)
subdirs(ismember(subdirs,{'.','..'})) = []; % remove . and .. subdirs
for s = 1:numel(subdirs)
    
    imgFiles = dir(fullfile(imgDirPath,subdirs{s},'*.jpg'));
    imgCount = imgCount + length(imgFiles);
    for i = 1:length(imgFiles)
        
        imgPath = fullfile(imgDirPath,subdirs{s},imgFiles(i).name);
        img = im2single(imread(imgPath));
        
        % we determine SIFT feature descriptors not at keypoints (e.g. corners) 
        % but rather on a regular grid! around 100 descriptors per img are sufficient.
        % we use vl_dsift (dense SIFT), which can quickly compute descriptors for 
        % densely sampled keypoints with identical size and orientation.
        % Option 'Fast' uses flat instead of Gaussian kernel
        % Option 'Step' means a SIFT descriptor is extracted each <Step> pixels.
        gridStepSize = 25;
        [frames, descriptors] = vl_dsift(img, 'Fast', 'Step', gridStepSize);
        siftFeatureDescriptors = [siftFeatureDescriptors descriptors]; % each column is one 128 elem SIFT feature vector
        
    end
end

avgFeaturesPerImg = round(size(siftFeatureDescriptors,2)/imgCount);
disp(sprintf('%d SIFT descriptors calculated from %d images on regular grid with %d pixel step size (avg. %d features per image.)', size(siftFeatureDescriptors,2), imgCount, gridStepSize, avgFeaturesPerImg));

%% Determine visual words as k-means cluster centers in 128 dimensional SIFT feature space
disp('Determine visual words as k-means cluster centers in 128 dimensional SIFT feature space...');
[centers, assignments] = vl_kmeans(single(siftFeatureDescriptors), numClusters);
vocabulary = centers;
disp(sprintf('Vocabulary of %d words (cluster centers) generated.', numClusters));

end
