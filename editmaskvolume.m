function editvol = editmaskvolume(editmask, numofslices, slicen)
% Companion function of the RodentAnalysisGUI for creating a 3D matrix
% that includes the mask created using freehand selection during the manual
% editing of the segmented regions. The size of this matrix is the same as
% the original matrix and all of its pixels are black except the ones in
% the mask.
%
% >> editvol = editmaskvolume(editmask, numofslices, slicen)
%
% Variable dictionary:
% --------------------
% editmask     input    The binary mask of the selected region.
% numoflices   input    The number of slices in the original 3D matrix.
% slicen       input    The number of the current slice of the matrix.
% editvol      output   The generated 3D matrix with the mask.
%
% Last Modified: 11 August 2016
% Copyright (c) 2016, Xenios Milidonis

% Get the size of the mask.
imagesize = size(editmask);

% Loop to create the 3D matrix with the editing mask.
for i = 1:numofslices
    % Check if this slice is the edited one. If not, create an empty slice.
    if i == slicen
        mask = editmask;
    else    
        mask = zeros(imagesize);   
    end
    
    % Create a 3D matrix of the mask.
    if i == 1                                       
        editvol = mask;
    else
        editvol = cat(3, editvol, mask);
    end
end

