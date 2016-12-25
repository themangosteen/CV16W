function [] = main(pathImgsTraining, pathImgsTest)
% CV16W ASSIGNMENT 5: Scene Recognition / Image Classification by Visual Bag of Visual Words Model
% pathImgsTraining ... path to directory of training images (JPG) used 
%                      to construct the vocabulary (bag) of visual words
%                      by clustering SIFT features taken from all imgs via k-means
%                      and using the cluster centers in the 128 dimensional 
%                      SIFT feature space (128 magnitudes whose orientation is ignored) as words.
%                      then for each individual training img (for which we know the classes)
%                      we take more SIFT features in the img and assign them 
%                      to their nearest-neighbor (kNN search with k=1) words (clusters),
%                      and then count how often each word occurred,
%                      thus having a histogram of visual words
%                      representing the class of this training img.
%                      Note: Images should be placed in subdirs of this
%                      dir, one subdir for each class of images
% pathImgsTest     ... path to directory of images to classify 
%                      based on comparison of word histograms with known classes

disp(sprintf('Note: Bag of Words does not operate in 2D image space, but in 128D SIFT feature space!\n2D spatial information in image is not relevant.'));
disp(sprintf('\nBUILD VOCABULARY OF VISUAL WORDS (K-MEANS CLUSTER CENTERS IN SIFT FEATURE SPACE)'));
vocabSize = 100;
vocabulary = BuildVocabulary(pathImgsTraining, vocabSize);

disp(sprintf('\nBUILD WORD HISTOGRAM FOR EACH TRAINING IMAGE WITH KNOWN CLASS'));
[trainingImgWordHistograms, trainingImgClasses] = BuildNNWordHistograms(pathImgsTraining, vocabulary);

disp(sprintf('\nCLASSIFY NEW IMAGES AND EVALUATE CLASSIFICATION'));
confusionMatrix = ClassifyImages(pathImgsTest, vocabulary, trainingImgWordHistograms, trainingImgClasses);
% determine percentage of correct classifications

end
