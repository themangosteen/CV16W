function [confusionMatrix] = ClassifyImages(imgDirPath, vocabulary, trainingImgWordHistograms, trainingImgClasses)
% Classify images by computing their visual word histograms
% and assigning the class most common among its k nearest neighbors
% in word histogram space (kNN classification).
% We then determine how often the classification was correct or not.
% 
% INPUT
% imgDirPath  ... image source directory, each class of images should have its own subdir
%                 images must be grayscale JPG
% vocabulary  ... visual words, i.e. cluster centers in SIFT feature space
%                 each columns is a 128 elem SIFT feature vector
% trainingImgWordHistograms ... word histogram of each training image
%                               each row is a word histogram of vocabulary length
% trainingImgClasses        ... class of each training image
%                               class index is training img subdir index
%
% OUTPUT
% confusionMatrix ... the value at position (i,j) indicates how often an
%                     image of class i is classified/predicted as class j.

%% Create word histogram for each image
disp('Create word histogram for each image to be classified...');

[imgWordHistograms, imgClassGroundTruth] = BuildNNWordHistograms(imgDirPath, vocabulary, 0);


%% Classify images using kNN classification
% Each image is assigned to the class most common among its k nearest neighbors
% in word histogram space.
k = 3;
disp(sprintf('Classify each image to class most common among its %d nearest neighbors in word histogram space...', k));

% Create kNN classification predictor model from training histograms and class ground truths
kNNPredictorTrained = fitcknn(trainingImgWordHistograms, trainingImgClasses, 'NumNeighbors', k);

% Predict classes of new images
imgClassPredicted = predict(kNNPredictorTrained, imgWordHistograms);

% Describe predicted classification result via confusion matrix,
% where the value at position (i,j) indicates how often an
% image of class i is classified/predicted as class j.
confusionMatrix = confusionmat(imgClassGroundTruth, imgClassPredicted);

end
