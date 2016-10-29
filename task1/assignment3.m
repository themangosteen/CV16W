function [ x, y, level ] = assignment3( path_to_input_image )
%ASSIGNMENT3  Scale-Invariant Blob Detection
%   with scale-normalized Laplacian of Gaussians operator

%% Standard Parameters
sigma0 = 2;
k = 1.25;
levels = 10;
threshold = 0.1;

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
scale_space = abs(scale_space); % only search for absolute maximums
scale_space(scale_space<threshold) = 0;
maxima = zeros(size(scale_space,1), size(scale_space,2),levels);
for i = 1:levels % check for maxima on all levels
    % compare with same level
      maxima(:,:,i) = compareWithLevel(scale_space(:,:,i), scale_space(:,:,i), true);

      % compare with level above (i+1)
    if i ~= levels % there exists a level above
        maxima(:,:,i) = maxima(:,:,i) & compareWithLevel(scale_space(:,:,i), scale_space(:,:,i+1), true);
    end
    
    % compare with level below (i-1)
    if i ~= 1 % there exists a level below
       maxima(:,:,i) = maxima(:,:,i) & compareWithLevel(scale_space(:,:,i), scale_space(:,:,i-1), true);
    end
end

% now in maxima there are 1s everywhere where a maximum is.
% find returns (linear) indices of nonzero values, ind2sub resizes them to 3
% components
% ex: 
% maxima =
% [0,0,0,0;
%  0,0,1,0;
%  0,0,0,0;...]
% find => [7,...]
% ind2sub => [3,2,1;...]
[x, y, level] = ind2sub(size(maxima),find(maxima)); 
showResults(image, x, y, level);
end

function [ resultOfComparisons ] = compareWithLevel( originalLevel, levelToCompare, same )
%UNTITLED Summary of this function goes here
%   same: true if the levels are the same and therefor the element should
%   not be compared with itself (levelToCompare without shifting)

% Use filters to move the image in every direction 1 pixel sperately in
% order to make the comparisons which are necessary for the finding of a
% maximum effective (no for-loops ;) )
filter = zeros(3,3,9);
filter(1,1,1) = 1;
filter(1,2,2) = 1;
filter(1,3,3) = 1;
filter(2,1,4) = 1;
filter(2,2,5) = 1;
filter(2,3,6) = 1;
filter(3,1,7) = 1;
filter(3,2,8) = 1;
filter(3,3,9) = 1;

if same
   % Unshifted same level consists of zeros for comparison, so there is 
   % always a maximum if you compare it with this level
    filter(2,2,5) = 0; 
end

resultOfComparisons = ones(size(originalLevel,1), size(originalLevel,2));

for i = 1:9 
    % move level with the help of filter defined above
    movedCompareLevel = imfilter(levelToCompare, filter(:,:,i));
    % compare with this level (but only if it is still possible that it is
    % a maximum in all directions)
    resultOfComparisons = resultOfComparisons & (originalLevel > movedCompareLevel);
end

% if resultOfComparisons is still true (1) at a position than this is a
% maximum in all 9 directions. Therefor we can now return this as result of
% the method.
end

function [  ] = showResults( image, x, y, level )
    show_all_circles(image, x, y, level*sqrt(2));
end