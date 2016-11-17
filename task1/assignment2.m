function [] = assignment2( filename, K, D )
% CV 16W ROUND 1 ASSIGNMENT 2: Image Segmentation by K-means Clustering
% Usage: assignment2(filename,K,D)
% Performs a kMeans-Clustering and shows an image as a result consisting of
% the pixels of each cluster colored in its centroid RGB-value
if D==3 || D==5
    %load image and initialize variables
    disp('Reading images and initializing values...');
    image = im2double(imread(filename));
    
    %1. Matrix consisting of k D-dimensional vectors �(=centroids) as
    %   starting values
    mu_k=random('Uniform',0,1,D,K);
    %Matrix which consists of the segmentation vectors of the image (used
    %instead of the image for better performance)
    image_matrix=zeros(D,size(image,1)*size(image,2));
    ratio = 14;
    termCrit = 1.01; %Ratio for which the clustering will terminate
    %Initial J for further ratio computation: The maximum distortion J is
    %the maximum (squared) magnitude of datapoint-centroids (=D) times the
    %number of datapoints
    Jay=14*D*size(image_matrix,2);
    index=1;
    
    %% Fill the input image in the image_matrix
    disp('Preparing data...');
    for i=1:size(image,1)
        for j=1:size(image,2)
            if D==3%just the RGB values for clustering
                image_matrix(:,index)=[image(i,j,1);image(i,j,2);image(i,j,3)];
            else%RGB and spatial information (normalized to [0,1]) for clustering
                image_matrix(:,index)=[image(i,j,1);image(i,j,2);image(i,j,3);i/size(image,1);j/size(image,2)];
            end
            index = index + 1;
        end
    end

    %% Do the clustering
    disp('Starting to cluster...');
    while ratio > termCrit %Ratio for which the clustering will terminate
        disp('Starting a new epoch...');
        %2. assign datapoints to nearest cluster centroids
        r_matrix=zeros(size(image,1)*size(image,2),K);
        nearestmatrix=zeros(D,size(mu_k,2));
        for i=1:size(image_matrix,2)
            %Subtract for each mu_k the datapoint - mu_k
            for j=1:size(mu_k,2)
                nearestmatrix(:,j)=image_matrix(:,i)-mu_k(:,j);
            end
            %Take the centroid with minimum distance to the datapoint
            [~,nearestindex]=min(sum(nearestmatrix.*nearestmatrix));
            r_matrix(i,nearestindex)=1;
        end

        %3. compute new centroids as mean of the data points in the cluster
        for i=1:size(mu_k,2)
            indizes=find(r_matrix(:,i)==1);
            %actually if the centroid �_k has no data points the mean should be
            %0 according to the assignment but it stays the same value instead
            if ~isempty(indizes)
                mu_k(:,i)=sum(image_matrix(:,indizes),2)/length(indizes);
            end
        end

        %4. compute J and check for convergence
        oldJay=Jay;
        Jay=0;
        for i=1:size(mu_k,2)
            %Take all values for which the ith centroid is assigned
            indizes=find(r_matrix(:,i)==1);
            if indizes ~= 0
                for j=1:length(indizes)
                    %add the squared magnitude of datapoint-mu_k to J
                    Jay = Jay + sum((image_matrix(:,indizes(j))-mu_k(:,i)).*(image_matrix(:,indizes(j))-mu_k(:,i)));
                end
            end
        end
        if Jay~=0%Centroids are exactly set to all colors existing in the image
            ratio=oldJay/Jay;
        else
            ratio=0;
        end
    end
    %Convergence reached, algorithm terminates
    disp('Finished clustering.');
    
    %Generate the output image and display
    outimg=zeros(size(image,1),size(image,2),3);
    %color each pixel with its clustercolor (if 5D only first 3 taken)
    index=1;
    for i=1:size(image,1)
        for j=1:size(image,2)
            for l=1:size(mu_k,2)
                if(r_matrix(index,l)==1)
                    outimg(i,j,1)=mu_k(1,l);
                    outimg(i,j,2)=mu_k(2,l);
                    outimg(i,j,3)=mu_k(3,l);
                end
            end
            index = index + 1;
        end
    end
    imshow(outimg);
else
    disp('Only 3D (RGB values of the pixels) and 5D (RGB and x,y of the pixels normalized) data points allowed!');
end
end