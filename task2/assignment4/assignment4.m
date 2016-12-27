%% Initialisation (Reading images)
close all; % close all open graphs
imagename = 'campus';
for i=1:5 % for every image
    path = strcat('img/',imagename,num2str(i),'.jpg');
    images(i,:,:) = im2double(rgb2gray(imread(path)));
end

%% A. SIFT Interest Point Detection
siftDescriptors = {};
siftFrames = {};
image = single(zeros(size(images,2),size(images,3))); % vl_sift needs single precision 
for i=1:5 % for every image
    image(:,:) = single(images(i,:,:)); % vl_sift needs axb as dim, not 1xaxb or 5xaxb
    [siftFrames{i},siftDescriptors{i}] = vl_sift(image);
    % Frames are featurePoints (coordinates, size, direction?)
    figure; 
    imshow(image)
    vl_plotframe(siftFrames{i}); % plot descriptors on top of image
end

%% B. Interest Point Matching and Image Registration
for i=1:4 % for every image pair
    % match feature points
    [matches,scores] = vl_ubcmatch(siftDescriptors{i},siftDescriptors{i+1});
    imageA = zeros(size(images,2),size(images,3)); % initialize
    imageB = zeros(size(images,2),size(images,3)); % initialize
    imageA(:,:) = images(i,:,:); % 1xaxb --> axb
    imageB(:,:) = images(i+1,:,:); % 1xaxb --> axb
    % extract the coordinates from the siftFrames matrix
    pointsA = siftFrames{i}(1:2,matches(1,:));
    pointsB = siftFrames{i+1}(1:2,matches(2,:));
    % Plot the results (matched feature points)
    match_plot(imageA, imageB, pointsA', pointsB');
end

%% C. Image Stitching