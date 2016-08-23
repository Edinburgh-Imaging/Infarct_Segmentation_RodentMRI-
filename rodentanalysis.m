function analysedvolmasks = rodentanalysis(vol, ipsimask, ni, nf, threshold)
% The main companion function of the RodentAnalysisGUI for thresholding
% the rodent brain images, creating corresponding masks and calculating the
% total lesion volume.
%
% >> analysedvolmasks = rodentanalysis(vol, ipsimask, ni, nf, threshold)
%
% Variable dictionary:
% --------------------
% vol              input    The image to be analysed (TIFF stack).
% ipsimask         input    Masks of the ipsilateral hemisphere (3D matrix).
% ni               input    Start the analysis on this slice.
% nf               input    Finish the analysis on this slice.
% threshold        input    The threshold to be used for analysis.
% analysedvolmasks output   Generated masks of the analysed images (3D
%                           matrix).
% 
% Last Modified: 12 August 2016
% Copyright (c) 2016, Xenios Milidonis

% LOOP FOR READING AND THRESHOLDING SLICES.
for i = 1:size(vol, 3)
    % Read each slice of the image and ipsimask consecutively. 
    image = vol(:, :, i);
    ipsi = ipsimask(:, :, i);

    % Fill the mask, just in case it is not filled already.
    ipsi = imfill(ipsi, 'holes'); 
    
    % Check if the mask for this slice has indeed any pixels.
    if (sum(ipsi(:)) == 0) || (i < ni) || (i > nf)
        % If not, the analysed image is blank.
        analysedimage = zeros(size(image));
    else
        % Blurring helps reducing black spots.
        h = fspecial('gaussian', [3, 3], 1);
        image = imfilter(image, h);
        % image = imgaussfilt(image, 1, 'FilterSize', 3); % not available for v < 2014 
        
        % Segment using the threshold (analysedimage is binary).
        analysedimage = im2bw(image, threshold);
        
        % Keep only the part of the analysed image that lies over the
        % ipsilateral hemisphere mask by finding their intersection.
        analysedimage = analysedimage & ipsi;
        
        % Fill if holes are present.
        analysedimage = imfill(analysedimage, 'holes');   
        
        % Remove small objects with pixels up to 1/5 of image height.
        analysedimage = bwareaopen(analysedimage,...
            ceil(size(analysedimage, 1)/5));  
    end

    analysedimage = +analysedimage; 
    
    % Create a 3D matrix of the masks.
    if i == 1                                     
        analysedvolmasks = analysedimage;
    else
        analysedvolmasks = cat(3, analysedvolmasks, analysedimage);
    end   
end
 
% FIND THE LARGEST CONNECTED COMPONENT IN 3D SPACE.
% Get all components (6 is the least dense connectivity).
conncomp = bwconncomp(analysedvolmasks, 6);   

% Identify the largest component using cellfun.
[~, maxcell] = max(cellfun(@numel, conncomp.PixelIdxList));      

% Zero the mask and assign to it the largest component.
analysedvolmasks = zeros(size(analysedvolmasks));
analysedvolmasks(conncomp.PixelIdxList{1, maxcell}) = 1;
       
