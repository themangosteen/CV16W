function [ output_args ] = assignment3( path_to_input_image )
%ASSIGNMENT3  Scale-Invariant Blob Detection
%   with scale-normalized Laplacian of Gaussians operator

%% Standard Parameters
sigma0 = 2;
k = 1.25;
levels = 10;

%% Preparation
image = im2double(imread(path_to_input_image)); % load image
scale_space = zeros(size(image,1),size(image,2),levels); % results after filtering
sigma = sigma0; % sigma: scale (of gauss etc)

%% Filter the image.
for i = 1:levels % calculate all sigmas (increase always by multiplying with constant k)
    filterSize = 2*floor(3*sigma)+1; % formular according to Details and Hints - Filter Creation
    logFilter = fspecial('log', filterSize, sigma); % create LoG filter
    % Use 'same' and 'replicate' to avoid artefacts at the borders and different
    % output dimensions.
    scale_space(:,:,i) = imfilter(image, logFilter, 'same', 'replicate');
    sigma = sigma*k; % change filter size of next iteration
end

%% Non-maximum suppression
for i = 1:levels
    % compare with level above (i+1)
    if i ~= levels
        %TODO
    end
    
    % compare with same level
      %TODO

    
    % compare with level below (i-1)
    if i ~= 1
       %TODO

    end
end


end

