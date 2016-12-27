%% Initialisation (Reading images)
imagename = 'campus';
for i=1:5 % for every image
    path = strcat('img/',imagename,num2str(i),'.jpg');
    images(i,:,:) = im2double(rgb2gray(imread(path)));
end

%% A. SIFT Interest Point Detection
image = single(zeros(size(images,2),size(images,3))); % vl_sift needs single precision
for i=1:5 % for every image
    image(:,:) = single(images(i,:,:)); % vl_sift needs axb as dim, not 1xaxb or 5xaxb
    [siftFrames,siftDescriptors] = vl_sift(image);
    % Frames are circles for descriptions of feature points
    figure; 
    imshow(image)
    vl_plotframe(siftFrames);
end

%% B. Interest Point Matching and Image Registration

%% C. Image Stitching