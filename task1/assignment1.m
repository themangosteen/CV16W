function[] = assignment1(imgfileR, imgfileG, imgfileB)
% CV 16W ROUND 1 ASSIGNMENT 1
% Combine possibly shifted RGB channel images by determining
% the necessery displacement to align them correctly
% via the Normalized Cross Correlation

    close all;
    clear global;
    
    % load images
    imgR = imread('Images and Functions/00125v_R.jpg');
    imgG = imread('Images and Functions/00125v_G.jpg');
    imgB = imread('Images and Functions/00125v_B.jpg');

    % determine how much to shift images [down right]
    displacementGtoR = determine_displacement_to_align(imgR, imgG);
    displacementBtoR = determine_displacement_to_align(imgR, imgB);

    % show combined rgb image
    imgRGB = cat(3, imgR, circshift(imgG, displacementGtoR), circshift(imgB, displacementBtoR));
    imshow(imgRGB, []);
    
    % optionally save combined image
    %imwrite(uint8(RGB_RESULT * 255), 'output.png', 'png');
end

function [displacementBtoA] = determine_displacement_to_align(imgA, imgB)
% Determine the necessary displacement for imgB in direction x and y,
% i.e. how much to shift imgB down and right, to best align it with imgA.
% The image matching metric used is the Normalized Cross-Correlation (NCC).
%
% INPUT
% imgA, imgB ... images for which to compute displacement for best alignment
% OUTPUT
% displacementBtoA ... vector storing best displacement in pixels [down right]

%TODO

% [shiftdown shiftright]
displacementBtoA = [0 0];

end