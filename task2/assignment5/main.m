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
% pathImgsTest     ... path to directory of images to classify 
%                      using trained bag of words system

disp('BUILD VOCABULARY OF VISUAL WORDS (K-MEANS CLUSTERS OF SIFT FEATURES)');
vocabSize = 100;
vocabulary = BuildVocabulary(pathImgsTraining, vocabSize);

disp('ASSOCIATE TRAINING IMG SIFT FEATURES WITH THEIR CLASSIFICATION'); % TODO reword
[trainingImgFeatures, trainingImgClassification] = BuildKNN(pathImgsTraining, vocabulary);

disp('CLASSIFY NEW IMAGES AND EVALUATE CLASSIFICATION');
confusion_matrix = ClassifyImages(pathImgsTest, vocabulary, trainingImgFeatures, trainingImgClassification);

end
