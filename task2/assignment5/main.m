function [] = main(pathImgsTraining, pathImgsTest)
% CV16W ASSIGNMENT 5: Scene Recognition / Image Classification by Visual Bag of Visual Words Model
% pathImgsTraining ... path to directory of training images (JPG or PNG) used 
%                      to construct the vocabulary (bag) of visual words
%                      which are k-means clusters of SIFT features from all imgs,
%                      and classify training imgs via k-Nearest-Neighbor
%                      of more SIFT features to the visual words (since we
%                      already know the classes this is actually used for
%                      finding SIFT features that correspond to those
%                      classes to later compare to test images).
%                      Note: Images should be placed in subdirs of this
%                      dir, one subdir for each class of images
% pathImgsTest     ... path to directory of images to classify 
%                      using trained bag of words system

% Note: Spatial information is not relevant in the whole process,
% images are classified purely by histograms of visual words!
% Visual words are clusters of SIFT features determined on a regular grid.

disp('BUILD VOCABULARY OF VISUAL WORDS (EACH WORD IS A K-MEANS CLUSTER OF SIFT FEATURES)');
vocabSize = 100;
vocabulary = BuildVocabulary(pathImgsTraining, vocabSize);

disp('ASSOCIATE TRAINING IMG SIFT FEATURES WITH THEIR CLASSIFICATION'); % TODO reword
[trainingImgFeatures, trainingImgClassification] = BuildKNN(pathImgsTraining, vocabulary);

disp('CLASSIFY NEW IMAGES AND EVALUATE CLASSIFICATION');
confusion_matrix = ClassifyImages(pathImgsTest, vocabulary, trainingImgFeatures, trainingImgClassification);
% determine percentage of correct classifications

end
