function threshold = estimatethreshold(vol, roimask, meanf, sdf)
% Companion function of the RodentAnalysisGUI for estimating the intensity
% threshold used for segmenting the lesion.
%
% >> threshold = estimatethreshold(vol, roimask, meanf, sdf)
%
% Variable Dictionary:
% --------------------
% vol         input     The 3D matrix from where the threshold is 
%                       calculated.
% roimask     input     The 3D matrix containing a mask of a healthy region
%                       in the contralateral hemisphere.
% meanf       input     The factor to multiply the mean intensity of the
%                       masked region.
% sdf         input     The factor to multiply the standard deviation of
%                       the intensity of the masked region.
% threshold   output    The calculated greyscale intensity threshold 
%                       (between [0, 1]).
%
% Last Modified: 17 March 2016
% Copyright (c) 2016, Xenios Milidonis

% Identify the slice where the roi is present.
for i = 1:size(roimask, 3)
    iroi = roimask(:, :, i);

    % Fill the roi, just in case it is not filled already.
    iroi = imfill(iroi, 'holes');
    
    % The slice of interest is the one with some white pixels.
    if sum(iroi(:)) ~= 0
        roislice = i;
        roi = iroi;
    end
end

% Read the image slice where the roi was drawn.
image = vol(:, :, roislice);

% Estimate the mean and standard deviation of the intensity of the 
% pixels in the contralateral corresponding to the roi mask.
roimean = mean(image(find(roi)));
roiSD = std(image(find(roi)));

% Calculate the threshold.
threshold = roimean * meanf + roiSD * sdf;

