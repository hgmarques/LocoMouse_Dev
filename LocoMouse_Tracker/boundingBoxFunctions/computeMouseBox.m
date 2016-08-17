function [bbi, cc, I_crop] = computeMouseBox(I,split_line,threshold)
% COMPUTEMOUSEBOX Computes the bounding box around the mouse on a
% background subtracted image.
%
% !!DO NOT EDIT THIS FILE!! 
% FOLLOW INSTRUCTIONS IN READ_BEFORE_CHANGING_ANYTHING.m
%
% Input:
% I: background subtracted grayscale image.
% split_line: pixel hight dividing the two views.
%
% Ouput:
% bounding box: a 2x3 matrix for [tl_x tl_y_bottom tl_y_top; ...
% width height_bottom height_top];
% cc: 2x2 matrix where the i-th column is the 2x1 image coordinates of the
% centroid of the bounding in view i (i == 1 is bottom). 
% I_crop: 2x1 cell with the bottom and top view cropped images.

if ~exist('threshold','var')
    threshold = 0.01;
end

% Estimating bounding box size:
Ibw = im2bw(medfilt2(I,[10 10]),threshold); % filtering to remove noise.
I_crop_bw = cell(1,2);
[I_crop_bw{[2 1]}] = splitImage(Ibw,split_line);clear Ibw;

bbi = zeros(4,2);
cc = zeros(2,2);


for i_v = 1:2
    % Selecting the largest object on the image (and hoping the mouse
    % does not have holes in it...):
    CC = bwconncomp(I_crop_bw{i_v});
    if isempty(CC.PixelIdxList)
        object_found(i_v) = false;
    else
        object_found(i_v) = true;
        
        [~,largest_object] = max(cellfun(@(x)(length(x)),CC.PixelIdxList));
        % Creating the new Ibw:
        Ibw = false(size(I_crop_bw{i_v}));Ibw(CC.PixelIdxList{largest_object}) = true;

        x_sum = sum(Ibw,1);
        y_sum = sum(Ibw,2);
        anybw1 = x_sum > 0;
        anybw2 = y_sum > 0;

        cc(:,i_v) = [((1:size(Ibw,2))*x_sum')/sum(x_sum);((1:size(Ibw,1))* y_sum)/sum(y_sum)];

        xi = find(anybw1,1,'first');
        xe = find(anybw1,1,'last');

        yi = find(anybw2,1,'first');
        ye = find(anybw2,1,'last');

        % Saving as BR corner and box size. Note that while the box size
        % is a global measure, the BR corner is defined per image. We chose the
        % right side as mice walk from left to right and so the right side of
        % the box is always the real location (it is not occluded). Remember
        % that images are reversed if animals walk right to left. We choose BR
        % instead of TR so that mapping from TR corner to the others is always
        % done by subtracting the hight and/or width of the box.
        if all(~cellfun(@isempty,{xi,xe,yi,ye}))
            bbi(:,i_v) = [xe;xe-xi;ye;ye-yi];
        end
    end
end
clear I_crop_bw
if any(object_found)
    bbi = [max(bbi(1:2,:),[],2) bbi(3:4,:)];
    x_cut = max(bbi(1,1) - bbi(2,1) + 1,1):bbi(1,1);
    [I_crop{[2 1]}] = splitImage(I,split_line);
    try
    if ~isempty(I_crop{1})
        I_crop{1} = I_crop{1}(max(1,bbi(1,2) - bbi(2,2) + 1):bbi(1,2),x_cut);
    end
    catch
        'fdx';
    end
    if ~isempty(I_crop{2})
        I_crop{2} = I_crop{2}(max(1,bbi(1,3) - bbi(2,3) + 1):bbi(1,3),x_cut);
    end
end