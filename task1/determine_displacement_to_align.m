function [displacementBtoA] = determine_displacement_to_align(imgA, imgB)
% Determine the necessary displacement for imgB in direction x and y,
% i.e. how much to shift imgB down and right, to best align it with imgA.
% The image matching metric used is the Normalized Cross-Correlation (NCC).
% Cross-Correlation (similar to convolution) for a given displacement is simply
% a weighted average of values in window in imgA using values from displaced window in imgB as weights.
% Normalization (subtract mean and divide by standard deviation)
% is needed since intensity range might vary in A and B.
%
% INPUT
% imgA, imgB ... images for which to compute displacement for best alignment
%                must have same dimensions!
% OUTPUT
% displacementBtoA ... vector storing best displacement in pixels [down right]

% arithmetic mean of all pixel values
meanA = sum(sum(imgA)) / numel(imgA); % sum of column sums divided by pixel count
meanB = sum(sum(imgB)) / numel(imgB);

% calculate ncc for each displacement and
% choose the displacement yielding the highest correlation
% TODO maybe more efficient to loop separately for rows and cols instead of
% for all values (30*2 calculations instead of 30^2)
% the assignment say exhaustively search over the window, optimization unnecessary
best_displacement = [0 0];
best_correlation = 0;
for shiftdown = -15:15
    for shiftright = -15:15
        displacement = [shiftdown shiftright];
        imgB_shifted = circshift(imgB, displacement);
        standarddeviation = sqrt(sum(sum((imgA-meanA).^2)).*sum(sum((imgB_shifted-meanB).^2))); 
        ncc = sum(sum((imgA-meanA).*(imgB_shifted-meanB))) / standarddeviation;
        %Alternative:
        %ncc=corr2(imgA,circshift(imgB,[shiftdown shiftright]));
        
        if ncc > best_correlation
           best_correlation = ncc;
           best_displacement = displacement;
        end
    end
end

% [shiftdown shiftright]
displacementBtoA = best_displacement;

end
