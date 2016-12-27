%% Initialisation (Reading images)
close all; % close all open graphs
imagename = 'campus';
ransacIterations = 1000;
ransacEucDistThreshold = 5;
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
    % Match feature points (with vl_ubcmatch)
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
    
    % RANSAC (find homography for inliers)
    currentlyBestNumberOfInliers = 0;
    currentlyBestInliers = [];
    currentlyBestTransformationMatrix = [];
    for j=1:ransacIterations
        % a) Randomly choose 4 matches
        % choose indices of matches (ex. take match #42, #142,...)
        indicesOfFourRandomMatches = randsample(1:size(matches,2),4);
        % get coordinates of those matched featurepoints
        coordinatesOfMatchedFeaturePointsInImageA = pointsA(:,indicesOfFourRandomMatches);
        coordinatesOfMatchedFeaturePointsInImageB = pointsB(:,indicesOfFourRandomMatches);
        % for debug purposes: draw those 4 matchings:
        % match_plot(imageA, imageB, coordinatesOfMatchedFeaturePointsInImageA', coordinatesOfMatchedFeaturePointsInImageB');
        
        % TODO: only use matchings that have not been used for matching
        
        % b) Estimate homography
        try % cp2tform throws an exception if for example the points are on a line
            % if projecting B to A (using a projective transformation):
            transformMatrix = cp2tform(coordinatesOfMatchedFeaturePointsInImageB',coordinatesOfMatchedFeaturePointsInImageA','projective');
            
            % c) Transform all other points of putative matches in the first image using tformfwd
            % (homography, x values, y values)
            [transformedBx,transformedBy] = tformfwd(transformMatrix, pointsB(1,:), pointsB(2,:));
            
            % d) Determine the number of inliers: compute the Euclidean distance between the trans-
            % formed points of the first image and the corresponding points of the second im-
            % age and count a match as inlier, if the distance is under a certain threshold T (e.g.
            % T = 5).
            eucDist = ((transformedBx-pointsA(1,:)).^2+(transformedBy-pointsA(2,:)).^2).^(1/2);
            inliers = false(size(eucDist,1),size(eucDist,2)); % init
            inliers(eucDist<ransacEucDistThreshold) = 1; % inlier are represented by 1s
            numberOfInliers = sum(inliers,2); % count all 1s
            if numberOfInliers>currentlyBestNumberOfInliers % take homography with maximal inliers
                currentlyBestNumberOfInliers = numberOfInliers;
                currentlyBestTransformationMatrix = transformMatrix;
                currentlyBestInliers = inliers;
            end
        catch
            disp('Points are on a line! Ignore this if it doesn''t happen too often...');
        end
    end
    % 4. After the N runs, take the homography that had the maximum number of inliers. Re-
    % estimate the homography with all inliers to obtain a more accurate result.
    coordinatesOfInlierFeaturePointsInImageA = pointsA(:,currentlyBestInliers);
    coordinatesOfInlierFeaturePointsInImageB = pointsB(:,currentlyBestInliers);
    transformMatrixOnlyWithInliers = cp2tform(coordinatesOfInlierFeaturePointsInImageB',coordinatesOfInlierFeaturePointsInImageA','projective');
    
    % 5. Transform the first image onto the second image. For this purpose, use the function
    % imtransform and specify the arguments 'Xdata' , 'Ydata' and 'XYScale' to get the
    % same dimension as the second image.
    referencePointsX = [1, 1, size(imageB,2), size(imageB,2)];
    referencePointsY = [1, size(imageB,1), 1, size(imageB,1)];
    [transformedX,transformedY] = tformfwd(transformMatrixOnlyWithInliers, referencePointsX, referencePointsY);
    xdata = [min(transformedX),max(transformedX)];
    ydata = [min(transformedY),max(transformedY)];

    %transformedImageB = imtransform(imageB, transformMatrixOnlyWithInliers, 'Xdata', xdata, 'Ydata', ydata, 'XYScale', xyscale);
    %transformedImageB = imtransform(imageB, transformMatrixOnlyWithInliers);
    %transformedImageB = imtransform(imageB, transformMatrixOnlyWithInliers, 'Xdata', xdata, 'Ydata', ydata, 'XYScale', [1,5]);
    %transformedImageB = imtransform(imageB, transformMatrixOnlyWithInliers, 'Xdata', [min(transformedBx),max(transformedBx)], 'Ydata', [min(transformedBy),max(transformedBy)], 'XYScale', [1,1]);
    %transformedImageB = imtransform(imageB, transformMatrixOnlyWithInliers, 'Xdata', [300,900], 'Ydata', [300,900]);
    transformedImageB = imtransform(imageB, transformMatrixOnlyWithInliers, 'Xdata', xdata, 'Ydata', ydata);

    figure
    imshow(imageB);
    figure
    imshow(transformedImageB);
%     imshow(imageA);
% both = imfuse(transformedImageB,imageA);
% imshow(both);
end


%% C. Image Stitching
% TODO