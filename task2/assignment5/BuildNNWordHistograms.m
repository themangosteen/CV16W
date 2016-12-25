function [trainingImgWordHistograms, trainingImgClasses] = BuildNNWordHistograms(imgDirPath, vocabulary)
% To represent each image by a histogram of visual words,
% we densely sample SIFT features in each image and assign them to their 
% nearest neighbor (kNN search with k=1) word, i.e. cluster center in SIFT
% feature space, counting how often SIFT features were assigned to each word.
% 
% INPUT
% imgDirPath  ... image source directory, each class of images should have its own subdir
% vocabulary  ... visual words, i.e. cluster centers in SIFT feature space
%                 each columns is a 128 elem SIFT feature vector
%
% OUTPUT
% trainingImgWordHistograms ... word histograms of all training images
%                               each row is a word histogram of vocabulary length
% trainingImgClasses        ... classes of all training images 
%                               class index is training img subdir index

%% Densely sample SIFT features in each image and count nearest neighbor assignments to each word (cluster center)
disp('Densely sample SIFT features in each image and count nearest neighbor assignments to each word (cluster center)...');

imgCount = 0; % total number of images used
descriptorCount = 0; % total number of SIFT feature descriptors
trainingImgWordHistograms = [];
trainingImgClasses = [];

d = dir(imgDirPath);
subdirs = {d([d(:).isdir]).name}; % subdirs (one for each class of images)
subdirs(ismember(subdirs,{'.','..'})) = []; % remove . and .. subdirs
for s = 1:numel(subdirs)
    
    imgFiles = dir(fullfile(imgDirPath,subdirs{s},'*.jpg'));
    imgCount = imgCount + length(imgFiles);
    for i = 1:length(imgFiles)
        
        imgPath = fullfile(imgDirPath,subdirs{s},imgFiles(i).name);
        img = im2single(imread(imgPath));
        
        % We densely sample SIFT feature descriptors on a regular grid, 
        % with step size of 1 or 2 pixels.
        % we use vl_dsift (dense SIFT), which can quickly compute descriptors for 
        % densely sampled keypoints with identical size and orientation.
        % Option 'Fast' uses flat instead of Gaussian kernel
        % Option 'Step' means a SIFT descriptor is extracted each <Step> pixels.
        gridStepSize = 10;
        [frames, imgDescriptors] = vl_dsift(img, 'Fast', 'Step', gridStepSize);
        descriptorCount = descriptorCount + size(imgDescriptors,2);
        
        % Assign each SIFT feature to its nearest neighbor word, 
        % i.e. cluster center in SIFT feature space.
        % kNN search with default k=1
        % this returns the vocabulary index of the nearest neighbor word for each feature
        nearestWordIndexForEachFeature = knnsearch(single(vocabulary)', single(imgDescriptors)');
        
        % Create word histogram for this image (count feature assignments to each word)
        % The histogram should be normalized since image size should not
        % influence word counts too much.
        imageWordHistogram = histcounts(nearestWordIndexForEachFeature, size(vocabulary,2));
        imageWordHistogram = normr(imageWordHistogram);
        
        trainingImgWordHistograms = [trainingImgWordHistograms; imageWordHistogram];
        trainingImgClasses = [trainingImgClasses; s]; % class index is subdir index
        
    end
end

avgFeaturesPerImg = round(descriptorCount/imgCount);
disp(sprintf('%d SIFT descriptors calculated from %d images on regular grid with %d pixel step size (avg. %d features per image.)', descriptorCount, imgCount, gridStepSize, avgFeaturesPerImg));
disp(sprintf('Visual word histograms of vocabulary size %d generated for each of %d images of %d classes.', size(vocabulary,2), imgCount, numel(subdirs)));

end
