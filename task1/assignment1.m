function[] = assignment1(imgfileR, imgfileG, imgfileB)
% CV 16W ROUND 1 ASSIGNMENT 1: Colorizing Images
% Usage: assignment1(filename_R, filename_G, filenameB)
% Combine possibly shifted RGB channel images by determining
% the necessery displacement to align them correctly
% via the Normalized Cross Correlation

    close all;
    clear global;
    
    % load images
    imgR = im2double(imread(imgfileR));
    imgG = im2double(imread(imgfileG));
    imgB = im2double(imread(imgfileB));

    % determine how much to shift G and B images relative to R
    displacementGtoR = determine_displacement_to_align(imgR, imgG);
    displacementBtoR = determine_displacement_to_align(imgR, imgB);

    % show combined rgb image
    imgRGB = cat(3, imgR, circshift(imgG, displacementGtoR), circshift(imgB, displacementBtoR));
    imshow(imgRGB, []);
    
    % optionally save combined image
    %imwrite(uint8(RGB_RESULT * 255), 'output.png', 'png');
end

