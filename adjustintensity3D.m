function adjustedvol =...
    adjustintensity3D(vol, method, excludemax, excludemin, varargin)
% It adjusts the intensity of a 3D greyscale matrix according to a number 
% of options.
%
% >> adjustedvol = adjustintensity3D(vol, method, excludemax, excludemin, 
%                  slicen)
%
% Variable Dictionary:
% --------------------
% vol          input   The 3D matrix the intensity of which must be 
%                      adjusted.
% method       input   The method to be used for intensity adjustment:
%                      'slicebyslice': Adjust the intensity of each slice 
%                          separately. This may lead to unwanted intensity 
%                          inhomogeneity across slices.
%                      'allslices': Adjust the intensity of the matrix 
%                          based on all slices. This may lead to unwanted 
%                          hypo- or hyperintensities if many white or black
%                          pixels are present in some slices, respectively.
%                      'basedonslice': Adjust the intensity of the matrix 
%                          based on a specified slice. 
% excludemax   input   'yes' or 'no' if pixels with maximum value should be
%                      excluded when selecting the limits for adjusting
%                      the intensity. Default is 'no'.
% excludemin   input   'yes' or 'no' if pixels with minimum value should be
%                      excluded when selecting the limits for adjusting
%                      the intensity. Default is 'no'.
% slicen       input   Optional. The slice number (positive integer) to be 
%                      used with method 'basedonslice'.
% adjustedvol  output  The created 3D matrix.
%
% Last Modified: 11 August 2016
% Copyright (c) 2016, Xenios Milidonis

% Find the number of slices in the input 3D matrix and other defaults.
numofslices = size(vol, 3);
        
% Check input variables.
if ~strcmp(method, {'slicebyslice', 'allslices', 'basedonslice'});
    error(['Input variable ''method'' must be either ''slicebyslice'',',...
        ' ''allslices'' or ''basedonslice''.']);
end
if strcmp(method, 'basedonslice') && size(varargin, 2) ~= 1
    error('For method ''basedonslice'' slice number is required.');
elseif strcmp(method, 'basedonslice')
    if (mod(varargin{1}, 1) == 0) && (sign(varargin{1}) == 1) 
        slicen = varargin{1};  % a positive integer        
        if slicen > numofslices
            error(['The provided slice number is larger than the number'...
                ' of slices in the input 3D matrix.']);
        end
    else
        error('Input variable ''slice'' must be a positive integer');
    end
end

% Adjust the intensity of the input volume. To note, imadjust works only on
% 2D greyscale images.
switch method
    case 'slicebyslice'
        % Adjust the intensity of each slice separately.
        adjustedvol = zeros(size(vol));

        for i = 1:numofslices
            slice = vol(:, :, i);
            maxvalue = double(max(slice(:)));
            minvalue = double(min(slice(:)));
            
            if strcmp(excludemax, 'yes')
                slice = slice(slice ~= maxvalue);
            elseif strcmp(excludemin, 'yes')
                slice = slice(slice ~= minvalue);
            elseif strcmp(excludemax, 'yes') && strcmp(excludemin, 'yes')
                slice = slice(slice ~= maxvalue);
                slice = slice(slice ~= minvalue);
            end
        
            adjustedvol(:, :, i) =...
                imadjust(vol(:, :, i), stretchlim(slice), []);
        end   
        
    case 'allslices'
        % Adjust the intensity of the volume based on all slices.
        newvol = vol;
        maxvalue = double(max(newvol(:)));
        minvalue = double(min(newvol(:)));
            
        if strcmp(excludemax, 'yes')
            newvol = newvol(newvol ~= maxvalue);
        elseif strcmp(excludemin, 'yes')
            newvol = newvol(newvol ~= minvalue);
        elseif strcmp(excludemax, 'yes') && strcmp(excludemin, 'yes')
            newvol = newvol(newvol ~= maxvalue);
            newvol = newvol(newvol ~= minvalue);
        end
        
        adjustedvol = imadjust(vol(:), stretchlim(newvol(:)), []);
        adjustedvol = reshape(adjustedvol, size(vol));
        
    case 'basedonslice'
        % Adjust the intensity of the volume based on a specified slice.
        slice = vol(:, :, slicen);
        maxvalue = double(max(slice(:)));
        minvalue = double(min(slice(:)));
            
        if strcmp(excludemax, 'yes')
            slice = slice(slice ~= maxvalue);
        elseif strcmp(excludemin, 'yes')
            slice = slice(slice ~= minvalue);
        elseif strcmp(excludemax, 'yes') && strcmp(excludemin, 'yes')
            slice = slice(slice ~= maxvalue);
            slice = slice(slice ~= minvalue);
        end
        
        adjustedvol = imadjust(vol(:), stretchlim(slice), []);
        adjustedvol = reshape(adjustedvol, size(vol));       
end     

