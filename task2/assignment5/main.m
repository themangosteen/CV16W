function [] = main(pathImgsTraining, pathImgsTest)
% CV16W ASSIGNMENT 5: Scene Recognition / Image Classification by Visual Bag of Visual Words Model
% pathImgsTraining ... path to directory of training images (JPG) used 
%                      to construct the vocabulary (bag) of visual words
%                      by clustering SIFT features taken from all imgs via k-means
%                      and using the cluster centers in the 128 dimensional 
%                      SIFT feature space (128 magnitudes whose orientation is ignored) as words.
%                      then for each individual training img (we know the class groundtruth of all images)
%                      we take more SIFT features in the img and assign them 
%                      to their nearest-neighbor (kNN search with k=1) words (clusters),
%                      and then count how often each word occurred,
%                      thus having a histogram of visual words
%                      representing the class of this training img.
%                      Note: Images should be placed in subdirs of this
%                      dir, one subdir for each class of images
% pathImgsTest     ... path to directory of images to classify, based on 
%                      comparison of word histograms to those of training images.
%                      each img is assigned the class most common among its 
%                      k nearest neighbor training imgs in word histogram space (kNN classification).

disp(sprintf('Note: Bag of Words does not operate in 2D image space, but in 128D SIFT feature space!\n2D spatial information in image is not relevant.'));
disp(sprintf('\nBUILD VOCABULARY OF VISUAL WORDS (K-MEANS CLUSTER CENTERS IN SIFT FEATURE SPACE)'));
vocabSize = 100;
vocabulary = BuildVocabulary(pathImgsTraining, vocabSize);

disp(sprintf('\nBUILD WORD HISTOGRAM FOR EACH TRAINING IMAGE'));
[trainingImgWordHistograms, trainingImgClasses] = BuildNNWordHistograms(pathImgsTraining, vocabulary, 1);

disp(sprintf('\nCLASSIFY NEW IMAGES AND COMPARE CLASSIFICATIONS TO THEIR GROUND TRUTH'));
confusionMatrix = ClassifyImages(pathImgsTest, vocabulary, trainingImgWordHistograms, trainingImgClasses);

% Evaluate classification results
disp(sprintf('\nEVALUATE CLASSIFICATION RESULTS'));
disp(sprintf('Print Confusion Matrix. Value at position (i,j) indicates \nhow often an image of class i is classified/predicted as class j.'));
confusionMatrix
disp(sprintf('Correct classifications are counted on main diagonal of Confusion Matrix. \nThus the trace (sum of diagonal elements) divided by the total gives the accuracy.'));
accuracy = trace(confusionMatrix) / sum(confusionMatrix(:));
disp(sprintf('ACCURACY: %d%%', round(accuracy*100)));

end
