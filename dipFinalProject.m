% CS 4560 - FINAL PROJECT
% Group 2
% Iris Segmentation
% Fall 2018

% Riley Evans
% Abigail Sandusky
% Lydia Snyder

%%%
%%%   IMPORTANT VARIABLES
%%%

brightnessScalar = 1.5;
pupilRadii = [22 66];
irisRadii = [66 150];
houghSensitivity = 0.90;
houghSensitivityBase = 0.90;


%%%
%%%   INITIALIZATION
%%%

file = uigetfile('*.*');
image = imread(file); 
original = image;
image = rgb2gray(image);
image = imresize(image, [NaN 500]);
%figure, imshow(original), axis image, title('Original Image');
[rows,columns] = size(image);

% Remove glare from eye
image =imcomplement(imfill(imcomplement(image),'holes'));
%figure, imshow(image), axis image, title('Glare-Fixed Image');

% Brighten and increase contrast
image = imadjust(image);
image = imadjust(image,[],[],1/brightnessScalar);
image = imadjust(image);
figure, imshow(image), axis image, title('Brightened Image');



%%%
%%%   CANNY EDGE DETECTION
%%%

% PHASE 1 - Gradient Filtering

% Gaussian Filter
kernal_size = 11;
kernal_padding = floor(kernal_size/2);
sigma = 1.8;
filter = zeros(kernal_size);

norm = 0;
for col = 1 : kernal_size
    for row = 1 : kernal_size
       x = (col-(kernal_padding+1))^2 + (row-(kernal_padding+1))^2;
       filter(col,row) = exp(-x/(2*sigma^2));
       norm = norm + filter(col,row);
    end
end
filter = filter / norm;
gaussian_image = conv2(image, filter, 'valid');
%figure, imshow(gaussian_image, []), axis image, title('Gaussian Blurred Image');

[Gx, Gy] = gradient(filter);
Fx = conv2(gaussian_image, Gx, 'same');
Fx = imcomplement(Fx);
Fy = conv2(gaussian_image, Gy, 'same');

mag = sqrt((Fx.^2)+(Fy.^2));
%figure, imshow(mag, []), axis image, title('Magnitude');
D = (atan2(Fy,Fx))*180/pi;
%figure, imshow(D, []), axis image, title('Theta');

% PHASE 2 - Nonmaximum Suppression

[newX,newY] = size(D);
newD = zeros(newX,newY);
for x = 1 : newX
    for y = 1 : newY
        
        if D(x,y) < 0
            D(x,y) = D(x,y) + 360; % makes all directions positive
        end
     
        D(x,y) = mod(D(x,y), 180);
        
        if  D(x,y) <= 22.5
            newD(x,y) = 0;
        elseif D(x,y) <= 67.5
            newD(x,y) = 45;
        elseif D(x,y) <= 112.5
            newD(x,y) = 90;
        elseif D(x,y) <= 157.5
            newD(x,y) = 135;
        elseif D(x,y) <= 180
            newD(x,y) = 0;
            
        end
    end
end

I = zeros(newX, newY);
for i = 2 : newX-1
    for j = 2 : newY-1
        if (newD(i,j)==0)
            I(i,j) = (mag(i,j) == max([mag(i,j), mag(i,j+1), mag(i,j-1)]));
        elseif (newD(i,j)==45)
            I(i,j) = (mag(i,j) == max([mag(i,j), mag(i+1,j-1), mag(i-1,j+1)]));
        elseif (newD(i,j)==90)
            I(i,j) = (mag(i,j) == max([mag(i,j), mag(i+1,j), mag(i-1,j)]));
        elseif (newD(i,j)==135)
            I(i,j) = (mag(i,j) == max([mag(i,j), mag(i+1,j+1), mag(i-1,j-1)]));
        end
    end
end
I = I.*mag;
%figure, imshow(I, []), axis image, title('Non-Max Suppressed');

% PHASE 3 - Hysteresis Thresholding

low = 0.05 * max(max(I));
high = 0.2 * max(max(I));
result = zeros (newX, newY);
for i = 1  : newX
    for j = 1 : newY
        if I(i, j) < low
            result(i, j) = 0;
        elseif I(i, j) > high
            result(i, j) = 1;
        elseif I(i+1,j)>high || I(i-1,j)>high || I(i,j+1)>high || I(i,j-1)>high || I(i-1, j-1)>high || I(i-1, j+1)>high || I(i+1, j+1)>high || I(i+1, j-1)>high
            result(i,j) = 1;
        end
    end
end
finalEdges = uint8(result.*255);
figure, imshow(finalEdges, []), axis image, title('Final Edges');



%%%
%%%   HOUGH TRANSFORM PUPIL DETECTION
%%%

figure, imshow(image, []), axis image, title('Pupil / Iris Detection');
pupilCenters = [];
irisCenters = [];
while isempty(pupilCenters)
    [pupilCenters, pupilR] = imfindcircles(finalEdges, pupilRadii, 'Sensitivity', houghSensitivity);
    houghSensitivity = houghSensitivity + 0.01
end
houghSensitivity = houghSensitivityBase;
viscircles(pupilCenters, pupilR, 'Color', 'b');
while isempty(irisCenters)
    [irisCenters, irisR] = imfindcircles(finalEdges, irisRadii, 'Sensitivity', houghSensitivity);
   houghSensitivity = houghSensitivity + 0.01
end
houghSensitivity = houghSensitivityBase;
viscircles(irisCenters, irisR, 'Color', 'r');


