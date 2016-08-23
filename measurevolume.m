function volume = measurevolume(vol, hpixsize, vpixsize, slicethickness)
% Companion function of the RodentAnalysisGUI for calculating the volume
% of objects in a 2D or 3D binary matrix. The volume per slice and the 
% total volume are shown in the Command Window and the latter is also 
% passed as an output on the GUI.
%
% >> volume = measurevolume(vol, hpixsize, vpixsize, slicethickness)
%
% Variable dictionary:
% --------------------
% vol              input    The binary matrix to be analysed.
% hpixsize         input    The size of the pixels horizontally (mm).
% vpixsize         input    The size of the pixels vertically (mm).
% slicethickness   input    The size of the pixels in the slice direction
%                           (mm).
% volume           output   The calculated total volume (mm^3).
% 
% Last Modified: 11 August 2016
% Copyright (c) 2016, Xenios Milidonis
    
% Display volumes in MATLAB command window.
disp('    Slice           mm^3    ');
        
% Define a column array to save area per slice.
volArray = zeros(size(vol, 3), 1);

% Calculate volume per slice.
for i = 1:size(vol, 3)
    slice = vol(:, :, i);
    
    % Count the number of pixels in each slice.
    slicelog = logical(slice);
    slicesum = sum(slicelog(:));

    % Fill area array with volume per slice.
    if isempty(slicesum) == 1
        volArray(i) = 0;
    else
        volArray(i) = slicesum * hpixsize * vpixsize * slicethickness;
    end

    formatspec = '%9d %14.3f\n';
    fprintf(formatspec, i, volArray(i));
end

% Calculate total volume.
volume = sum(volArray);
volumeinpixels = round(volume / hpixsize / vpixsize / slicethickness);

fprintf('%9s %14.3f\n', 'Total', volume);
fprintf('%9s %14d\n', 'Pixels', volumeinpixels);

