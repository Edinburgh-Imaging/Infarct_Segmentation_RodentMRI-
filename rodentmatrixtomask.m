function masks = rodentmatrixtomask(vertices, imagesize)
% Companion function of the RodentAnalysisGUI for creating masks using 
% polygon vertice coordinates. This function uses MATLAB's poly2mask 
% function, which cannot write multiple regions on the same mask. The
% coordinates can be obtained using MATLAB's roipoly function.
%
% >> masks = rodentmatrixtomask(vertices, imagesize)
%
% Variable dictionary:
% --------------------
% vertices     input    3D matrix with the coordinates of the vertices.
% imagesize    input    1x2 vector of the size of the masks. The size in 
%                       the 3rd dimension is the size of 'vertices'.
% masks        output   The generated 3D matrix of the masks.
%
% Last Modified: 11 August 2016
% Copyright (c) 2016, Xenios Milidonis

% Get the number of slices.
numofslices = size(vertices, 3);

% LOOP OVER VERTICES TO CREATE MASKS.
for i = 1:numofslices
    oldcoordinates = vertices(:, :, i);

    % Check if there are indeed any vertices for this slice.
    if sum(oldcoordinates(:)) == 0
        mask = zeros(imagesize);
    else    
        % Removing 0s works only along individual columns. 
        xcoordinates = oldcoordinates(:, 1);
        ycoordinates = oldcoordinates(:, 2);
        xcoordinates = xcoordinates(xcoordinates ~= 0);
        ycoordinates = ycoordinates(ycoordinates ~= 0);

        % Now, concatenate horizontally.
        coordinates = horzcat(xcoordinates, ycoordinates); 

        % Polymask needs row coordinate vectors.
        coordinates = round(coordinates.');

        % Create a mask with the specified input size using polymask.
        mask = poly2mask(coordinates(1, :), coordinates(2, :),...
            imagesize(1), imagesize(2));   
    end
    
    % Create a 3D matrix of the mask.
    if i == 1                                       
        masks = mask;
    else
        masks = cat(3, masks, mask);
    end
end

