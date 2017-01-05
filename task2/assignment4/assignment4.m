function assignment4(varargin)
% CV 16W ROUND 2 ASSIGNMENT 4: Image Stitching
% Usage: assignment4
%        assignment4('image_series')
%        assignment4('image_series',noborders)
%        WARNING: parameters must be valid! Both parameters optional
% 'image_series'... name of the image series that should be combined to one
%                   image (without the numbering and extension as a
%                   string). Pictures have to be saved with proper naming:
%                   continous numbering from 1 to N following with .jpg
%                   directly after the given input name.
%                   Save your series in img/ subfolder!
% noborders...      crops the image so that nearly no black borders are
%                   seen in the combined image
% Combines and odd number of horizontal images with continous numbering
% together to one big image.

%Flags and warnings
protocol=0; %1 to save all images needed for report in img/result
nowarnings=1; %deactivate numerical matrix computation warnings
noborders=0; %1=nearly no black borders, 0=full images with borders
if(nowarnings)
    %find with [~,MSGID]=lastwarn();
    warning('off','MATLAB:nearlySingularMatrix')
    warning('off','images:maketform:conditionNumberofAIsHigh')
    warning('off','MATLAB:nearlySingularMatrix')
    warning('off','MATLAB:singularMatrix')
end
imagename = 'campus'; % name of image series
if(nargin>=1)
    imagename = varargin{1};
end
if(nargin>=2)
    noborders=varargin{2};
end

%% Initialisation (Reading images)
close all; % close all open graphs
ransacIterations = 1000;
ransacEucDistThreshold = 5;
%Number of images, has to be and odd number (referenceFrame is always the middle one)
NoofImages=1;
while true
    path = strcat('img/',imagename,num2str(NoofImages),'.jpg');
    if(~exist(path,'file'))
        if(mod(NoofImages,2)==1)%if NoofImages isn't odd abort
            disp('Error: Number of images isn''t odd or filename does not exist! Aborting.')
            return
        end
        NoofImages=NoofImages-1;
        break;
    end
    images(NoofImages,:,:) = im2double(rgb2gray(imread(path)));%A and B
    colorimages(NoofImages,:,:,:)=im2double(imread(path));%C and final image
	NoofImages=NoofImages+1;
end

%% A. SIFT Interest Point Detection
siftDescriptors = {};
siftFrames = {};
image = single(zeros(size(images,2),size(images,3))); % vl_sift needs single precision
for i=1:NoofImages % for every image
    image(:,:) = single(images(i,:,:)); % vl_sift needs axb as dim, not 1xaxb or 5xaxb
    [siftFrames{i},siftDescriptors{i}] = vl_sift(image);
    % Frames are featurePoints (coordinates, size, direction?)
    if(protocol)
        figure;
        imshow(image)
        vl_plotframe(siftFrames{i}); % plot descriptors on top of image
        print(strcat('img/results/SiftFeatures',num2str(i)),'-dpng');
    end
end

%% B. Interest Point Matching and Image Registration
for i=1:NoofImages-1 % for every image pair
    % Match feature points (with vl_ubcmatch)
    [matches,~] = vl_ubcmatch(siftDescriptors{i},siftDescriptors{i+1});
    imageA = zeros(size(images,2),size(images,3)); % initialize
    imageB = zeros(size(images,2),size(images,3)); % initialize
    imageA(:,:) = images(i,:,:); % 1xaxb --> axb
    imageB(:,:) = images(i+1,:,:); % 1xaxb --> axb
    % extract the coordinates from the siftFrames matrix
    pointsA = siftFrames{i}(1:2,matches(1,:));
    pointsB = siftFrames{i+1}(1:2,matches(2,:));
    pointsAoMA=pointsA;
    pointsBoMB=pointsB;
    if(protocol)
        % Plot the results (matched feature points)
        match_plot(imageA, imageB, pointsA', pointsB');
        print(strcat('img/results/Matchings',num2str(i),'-',num2str(i+1)),'-dpng');
    end

    % RANSAC (find homography for inliers)
    currentlyBestNumberOfInliers = 0;
    coordinatesOfInlierFeaturePointsInImageA=[];
    coordinatesOfInlierFeaturePointsInImageB=[];
    for j=1:ransacIterations
        % a) Randomly choose 4 matches
        % choose indices of matches (ex. take match #42, #142,...)
        indicesOfFourRandomMatches = randsample(1:size(matches,2),4);
        % get coordinates of those matched featurepoints
        coordinatesOfMatchedFeaturePointsInImageA = pointsA(:,indicesOfFourRandomMatches);
        coordinatesOfMatchedFeaturePointsInImageB = pointsB(:,indicesOfFourRandomMatches);
        %only use points that have not been used for matching, transforms
        %and measures distance for inliers only for all but the 4 random
        %chosen points, comment out the next 2 lines to take all points
        %instead for looking for the most inliers
        pointsAoMA=pointsA(:,setdiff(1:size(pointsA,2),indicesOfFourRandomMatches));
        pointsBoMB=pointsB(:,setdiff(1:size(pointsB,2),indicesOfFourRandomMatches));
        % for debug purposes: draw those 4 matchings:
        % match_plot(imageA, imageB, coordinatesOfMatchedFeaturePointsInImageA', coordinatesOfMatchedFeaturePointsInImageB');
        
        % b) Estimate homography
        try % cp2tform throws an exception if for example the points are on a line
            % if projecting B to A (using a projective transformation):
            transformMatrix = cp2tform(coordinatesOfMatchedFeaturePointsInImageB',coordinatesOfMatchedFeaturePointsInImageA','projective');
            
            % c) Transform all other points of putative matches in the first image using tformfwd
            % (homography, x values, y values)
            [transformedBx,transformedBy] = tformfwd(transformMatrix, pointsBoMB(1,:), pointsBoMB(2,:));
            
            % d) Determine the number of inliers: compute the Euclidean distance between the trans-
            % formed points of the first image and the corresponding points of the second im-
            % age and count a match as inlier, if the distance is under a certain threshold T (e.g.
            % T = 5).
            eucDist = ((transformedBx-pointsAoMA(1,:)).^2+(transformedBy-pointsAoMA(2,:)).^2).^(1/2);
            inliers = false(size(eucDist,1),size(eucDist,2)); % init
            inliers(eucDist<ransacEucDistThreshold) = 1; % inlier are represented by 1s
            numberOfInliers = sum(inliers,2); % count all 1s
            if numberOfInliers>currentlyBestNumberOfInliers % take homography with maximal inliers
                currentlyBestNumberOfInliers = numberOfInliers;
                coordinatesOfInlierFeaturePointsInImageA=pointsAoMA(:,inliers);
                coordinatesOfInlierFeaturePointsInImageB=pointsBoMB(:,inliers);
            end
        catch
            if(~nowarnings)
            disp('Points are on a line! Ignore this if it doesn''t happen too often...');
            end
        end
    end
    % 4. After the N runs, take the homography that had the maximum number of inliers. Re-
    % estimate the homography with all inliers to obtain a more accurate result.
    transformMatrixOnlyWithInliers = cp2tform(coordinatesOfInlierFeaturePointsInImageB',coordinatesOfInlierFeaturePointsInImageA','projective');
    if(protocol)%whole 5. is only needed for the protocol as the transformation with more than 2 images is done at point C
        % Plot the matches of the inliers after step 4
        match_plot(imageA, imageB, coordinatesOfInlierFeaturePointsInImageA', coordinatesOfInlierFeaturePointsInImageB');
        print(strcat('img/results/MatchingsInliers',num2str(i),'-',num2str(i+1)),'-dpng');

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
        imageAWithBDimensions(1-ydata(1):size(imageA,1)-ydata(1),1-xdata(1):size(imageA,2)-xdata(1)) = imageA;
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
    
    %save every transformation between to images for the image stitching
    H(i)=transformMatrixOnlyWithInliers;
end

close all; % close all plots/graphs because there are too much. Open them in the img/results folder if needed
%% C. Image Stitching
% 1. Determine homographies between all image pairs - done in B
% H(1-(NoofImages-1))
% 2. Choose a reference image (always the middle is chosen), compute all
% homographies that map the other images to the reference images
% For ease of computation the NoofImages-1 homographies will be extended to
% NoofImages homographies; so every image can be transformed with its own
% transformation
referenceImage=floor(NoofImages/2)+1;
%Transformations from reference to the left:
%H_{ref,ref-1}*H_{ref-1,ref-2}...
for i=referenceImage-1:-1:1
    RefH(i)=H(referenceImage-1);%=H_{ref-1,ref}
    RefH(i).tdata.T=H(referenceImage-1).tdata.Tinv;
    RefH(i).tdata.Tinv=H(referenceImage-1).tdata.T;
    for j=referenceImage-2:-1:i
        RefH(i).tdata.T=RefH(i).tdata.T*H(j).tdata.Tinv;
        RefH(i).tdata.Tinv=RefH(i).tdata.Tinv*H(j).tdata.T;
    end
end
%RefH(referenceImage)=do not change anything, so just do a transformation
%with the identity
RefH(referenceImage)=H(1);
RefH(referenceImage).tdata.T=eye(length(RefH(referenceImage).tdata.T));
RefH(referenceImage).tdata.Tinv=RefH(referenceImage).tdata.T;
%Transformations from reference to the right: H_{ref,ref+1}*H_{ref+1,ref+2}
for i=referenceImage+1:NoofImages
    RefH(i)=H(referenceImage);%=H_{ref,ref+1}
    for j=referenceImage+2:i
        RefH(i).tdata.T=RefH(i).tdata.T*H(j-1).tdata.T;
        RefH(i).tdata.Tinv=RefH(i).tdata.Tinv*H(j-1).tdata.Tinv;
    end
end

% 3. Compute the size of the output panorama image (as done in B 5.)
RefImage=images(referenceImage,:,:);
for i=1:NoofImages
    %for every image the borders are transformed
    referencePointsX = [1, 1, size(images(i,:,:),3), size(images(i,:,:),3)];
    referencePointsY = [1, size(images(i,:,:),2), 1, size(images(i,:,:),2)]; 
    [transformedX(i,:),transformedY(i,:)] = tformfwd(RefH(i), referencePointsX, referencePointsY);
end
if(noborders)
    %"borderless"-version
    xdimfinal = [ceil(min(min(min(transformedX)),0)),floor(max(max(max(transformedX)),size(RefImage,3)))];
    ydimfinal = [0 size(RefImage,2)];
else
    %standard, take the "bounding box" containing of the outest points of all images
    xdimfinal = [floor(min(min(min(transformedX)),0)),ceil(max(max(max(transformedX)),size(RefImage,3)))];
    ydimfinal = [floor(min(min(min(transformedY)),0)),ceil(max(max(max(transformedY)),size(RefImage,2)))];
end

% 4. Transform all images to the plane (as done in B 5.)
for i=1:NoofImages
    % transform the image using the matrix and the bounding box of all images
    transformedImages(i,:,:,:) = imtransform(squeeze(colorimages(i,:,:,:)), RefH(i), 'Xdata', xdimfinal, 'Ydata', ydimfinal);
    % for debug purposes: plot each of the transformed images
    %figure
    %imshow(squeeze(transformedImages(i,:,:,:)));
end

%for debug purposes: all pictures combined with max:
% debugimage=zeros(size(transformedImages,2),size(transformedImages,3),size(transformedImages,4));
% for i=1:size(transformedImages,2)
%     for j=1:size(transformedImages,3)
%         debugimage(i,j,1)=max(transformedImages(:,i,j,1));
%         debugimage(i,j,2)=max(transformedImages(:,i,j,2));
%         debugimage(i,j,3)=max(transformedImages(:,i,j,3));
%     end
% end
% figure
% imshow(debugimage);
if(protocol)
    %Version which overlays from the side images to the middle one after
    %the other (only one image used for every pixel i.e. the information
    %of the most centered image is taken alone)
    blendlessimage=zeros(size(transformedImages,2),size(transformedImages,3),size(transformedImages,4));
     for k=1:referenceImage-1
         for i=1:size(transformedImages,2)
              for j=1:size(transformedImages,3)
                  if(transformedImages(k,i,j,1)||transformedImages(k,i,j,2)||transformedImages(k,i,j,3))
                    blendlessimage(i,j,1)=transformedImages(k,i,j,1);
                    blendlessimage(i,j,2)=transformedImages(k,i,j,2);
                    blendlessimage(i,j,3)=transformedImages(k,i,j,3);
                  end
              end
          end
     end
     for k=NoofImages:-1:referenceImage+1
         for i=1:size(transformedImages,2)
              for j=1:size(transformedImages,3)
                  if(transformedImages(k,i,j,1)||transformedImages(k,i,j,2)||transformedImages(k,i,j,3))
                    blendlessimage(i,j,1)=transformedImages(k,i,j,1);
                    blendlessimage(i,j,2)=transformedImages(k,i,j,2);
                    blendlessimage(i,j,3)=transformedImages(k,i,j,3);
                  end
              end
          end
     end
      for i=1:size(transformedImages,2)
          for j=1:size(transformedImages,3)
              if(transformedImages(referenceImage,i,j,1)||transformedImages(referenceImage,i,j,2)||transformedImages(referenceImage,i,j,3))
                blendlessimage(i,j,1)=transformedImages(referenceImage,i,j,1);
                blendlessimage(i,j,2)=transformedImages(referenceImage,i,j,2);
                blendlessimage(i,j,3)=transformedImages(referenceImage,i,j,3);
              end
          end
      end
    figure
    imshow(blendlessimage);
end

% 5. blend overlapping pixel color values
%create achannel image
%all values zeros except the border (there 1)
achannel=zeros(size(images,2),size(images,3));
achannel(:,1)=1;
achannel(:,end)=1;
achannel(1,:)=1;
achannel(end,:)=1;
%Interpolate over all matrix elements with bwdist to get alphachannel
achannel=bwdist(achannel)/max(max(bwdist(achannel)));
%make one channel for every image
achannels=repmat(achannel,[1 1 size(images,1)]);
%transform the alphachannels exactly like the RGB-images
for i=1:NoofImages
    transformedachannels(i,:,:) = imtransform(squeeze(achannels(:,:,i)), RefH(i), 'Xdata', xdimfinal, 'Ydata', ydimfinal);
end
%Compute the output image with formula:
%O(x,y)=(Sum{i=1}{n}(R_i,G_i,B_i)*alpha_i)/(Sum{i=1}{n}alpha_i)
finalimage(:,:,1)=sum((transformedImages(:,:,:,1).*transformedachannels(:,:,:)))./sum(transformedachannels(:,:,:));
finalimage(:,:,2)=sum((transformedImages(:,:,:,2).*transformedachannels(:,:,:)))./sum(transformedachannels(:,:,:));
finalimage(:,:,3)=sum((transformedImages(:,:,:,3).*transformedachannels(:,:,:)))./sum(transformedachannels(:,:,:));
%final image
figure
imshow(finalimage);

warning('on','MATLAB:nearlySingularMatrix')
warning('on','images:maketform:conditionNumberofAIsHigh')
warning('on','MATLAB:nearlySingularMatrix')
warning('on','MATLAB:singularMatrix')
end
