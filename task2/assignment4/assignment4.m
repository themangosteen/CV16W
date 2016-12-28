function assignment4()
% Function for assignment4. No parameters necessary.

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
    print(strcat('img/results/SiftFeatures',num2str(i)),'-dpng');
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
    print(strcat('img/results/Matchings',num2str(i),'-',num2str(i+1)),'-dpng');

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
    % See were the corner points of the image are projected to.
    referencePointsX = [1, 1, size(imageB,2), size(imageB,2)];
    referencePointsY = [1, size(imageB,1), 1, size(imageB,1)];
    [transformedX,transformedY] = tformfwd(transformMatrixOnlyWithInliers, referencePointsX, referencePointsY);
    % define something like a bounding box (create a space in which the original imageA and
    % the projected imageB can be combined):
    xdata = [min(min(transformedX),0),max(max(transformedX),size(imageA,2))];
    ydata = [min(min(transformedY),0),max(max(transformedY),size(imageA,1))];
    
    % transform the image using the matrix and the bounding box
    transformedImageB = imtransform(imageB, transformMatrixOnlyWithInliers, 'Xdata', xdata, 'Ydata', ydata);
    
    % imageA with a black border around to match the dimensions of the
    % transformed
    imageAWithBDimensions = zeros(size(transformedImageB));
    % 1-ydata(1) because there a (negative) value is stored if the
    % transformed image results in an image above the original image. Then
    % the original image has to be shifted down and cannot start at (1,1)
    % but (1+x,1) and because in ydata there is saved -x saved we take 1-x.
    imageAWithBDimensions(1-ydata(1):size(imageA,1)-ydata(1),1:size(imageA,2)) = imageA;
    combinedByTakingMax = max(transformedImageB, imageAWithBDimensions);
    figure
    imshow(combinedByTakingMax);
    title('Combined by taking the maximum value');
    print(strcat('img/results/MaxCombination',num2str(i),'-',num2str(i+1)),'-dpng');

    
    diffImage = abs(transformedImageB-imageAWithBDimensions);
    figure
    imshow(diffImage);
    title('Difference between original image and other projected image');
    print(strcat('img/results/DiffCombination',num2str(i),'-',num2str(i+1)),'-dpng');

end


%% C. Image Stitching
% TODO

end