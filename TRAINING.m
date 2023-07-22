function varargout = TRAINING(varargin)
% TRAINING MATLAB code for TRAINING.fig
%      TRAINING, by itself, creates a new TRAINING or raises the existing
%      singleton*.
%
%      H = TRAINING returns the handle to a new TRAINING or the handle to
%      the existing singleton*.
%
%      TRAINING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRAINING.M with the given input arguments.
%
%      TRAINING('Property','Value',...) creates a new TRAINING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TRAINING_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TRAINING_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TRAINING

% Last Modified by GUIDE v2.5 03-Jul-2023 19:32:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TRAINING_OpeningFcn, ...
                   'gui_OutputFcn',  @TRAINING_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before TRAINING is made visible.
function TRAINING_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TRAINING (see VARARGIN)
hback = axes('units','normalized','position',[0 0 1 1]);
uistack(hback, 'bottom');
[back, map] = imread('Menu.jpeg');
image(back)
colormap(map)
background = imread('Menu.jpeg');
set(hback,'handlevisibility','off','visible','off');
% Choose default command line output for TRAINING
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TRAINING wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
% --- Executes on button press in btnLoadDataset.
function btnLoadDataset_Callback(hObject, eventdata, handles)
% hObject    handle to btnLoadDataset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get the current working directory (project folder)
clc; clear; close all;
% Menentukan folder dataset
datasetFolder = 'testing';

% Mengecek apakah folder dataset kosong atau tidak ada
if isempty(datasetFolder) || ~isfolder(datasetFolder)
    errordlg('Please specify a valid dataset folder before starting the training.', 'Error', 'modal');
    return;
end

% Menentukan pola file gambar yang sesuai dengan folder dataset
pattern1 = 'daunjambuair*.jpg';
pattern2 = 'daunjambubiji*.jpg';

% Mengambil nama file yang sesuai dengan pola yang ditentukan
fileNames1 = dir(fullfile(datasetFolder, pattern1));
fileNames2 = dir(fullfile(datasetFolder, pattern2));

% Menggabungkan jalur folder dengan nama file untuk mendapatkan jalur file lengkap
imageFiles1 = fullfile(datasetFolder, {fileNames1.name});
imageFiles2 = fullfile(datasetFolder, {fileNames2.name});

% Menggabungkan kedua set jalur file gambar
imageFiles = [imageFiles1, imageFiles2];

% Menginisialisasi database fitur
ciri_database = zeros(numel(imageFiles), 14); % Ditingkatkan menjadi 14 untuk fitur tambahan
index = 1;

% Membuat waitbar untuk menampilkan progress
hWaitBar = waitbar(0, 'Training in progress...', 'Name', 'Training', 'WindowStyle', 'modal');

% Mengulangi setiap file gambar
for i = 1:numel(imageFiles)
    % Memperbarui progress waitbar
    waitbar(i / numel(imageFiles), hWaitBar, sprintf('Training image %d of %d', i, numel(imageFiles)));
    
    % Membaca file gambar
    Img = imread(imageFiles{i});
    
    % Pre-processing
    
    % Mendapatkan ukuran gambar asli
    [height, width, ~] = size(Img);

    % Menyesuaikan nilai bbox agar mencakup seluruh gambar
    bbox = [1, 1, width, height];

    % Melakukan cropping pada gambar dengan bbox yang disesuaikan
    croppedImg = imcrop(Img, bbox);

    % Menampilkan hasil gambar croppedImg
    %     imshow(croppedImg);
    %     title('Cropped Image');

    
    % Menghilangkan noise dengan filter median atau filter gaussian
    preprocessedImg = filterMedianOrGaussian(croppedImg);
    
    % Meningkatkan kontras dan kecerahan gambar
    enhancedImg = enhanceContrastAndBrightness(preprocessedImg);
    %     imshow(enhancedImg);
    %     title('Meningkatkan kontras dan kecerahan gambar');
    
    % Segmentasi daun dari latar belakang
    segmentedImg = leafSegmentation(enhancedImg);
    %     imshow(segmentedImg);
    %     title('Segmentasi daun dari latar belakang');
    
    % Ekstraksi fitur menggunakan metode yang telah ditentukan
    % Ekstraksi fitur HSV
    hsvFeatures = extractHSVFeatures(segmentedImg);
    expectedSizeHsv = 3;
    assert(numel(hsvFeatures) == expectedSizeHsv, 'The size of HSV features is not correct.');

    % Ekstraksi fitur GLCM
    glcmFeatures = extractGLCMFeatures(segmentedImg);
    
    % Ekstraksi fitur bentuk
    shapeFeatures = extractShapeFeatures(segmentedImg);
    
    % Properti ukuran daun
    sizeFeatures = extractSizeFeatures(segmentedImg);
    
    % Menggabungkan semua fitur menjadi satu vektor fitur
    featureVector = [hsvFeatures, glcmFeatures, shapeFeatures, sizeFeatures];
    
    % Mengecek ukuran featureVector
    if numel(featureVector) ~= 14
        errordlg('The size of the feature vector is not correct.', 'Error', 'modal');
        return;
    end
    
    % Menyimpan vektor fitur ke dalam ciri_database
    ciri_database(index, :) = featureVector;
    index = index + 1;
end

% Menyimpan database fitur ke file Excel
filename = 'ciri_database_dataset-test-record.xlsx';
headers = {'Hue', 'Saturation', 'Value', 'Contrast', 'Correlation', 'Energy', 'Homogeneity', 'ShapeFeature1', 'ShapeFeature2', 'SizeFeature1', 'SizeFeature2', 'SizeFeature3', 'SizeFeature4', 'SizeFeature5'};
xlswrite(filename, headers, 'Sheet1', 'A1');
xlswrite(filename, ciri_database, 'Sheet1', 'A2');
save ciri_database_dataset-test-record.mat ciri_database

% Menampilkan pesan berhasil
close(hWaitBar);
TRAINING
s = msgbox('Data Training Berhasil', 'status');


% Fungsi untuk ekstraksi properti ukuran daun
function sizeFeatures = extractSizeFeatures(image)
% Ekstraksi properti ukuran daun
% Hitung panjang dan lebar daun
lengthLeaf = size(image, 1);
widthLeaf = size(image, 2);

% Hitung diameter daun
diameterLeaf = sqrt(lengthLeaf^2 + widthLeaf^2);

% Hitung aspek rasio
aspectRatio = lengthLeaf / widthLeaf;

% Menyimpan properti ukuran daun dalam vektor
sizeFeatures = [lengthLeaf, widthLeaf, diameterLeaf, aspectRatio];


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;
MENU


% Fungsi untuk menghilangkan noise dengan filter median atau filter gaussian
function preprocessedImg = filterMedianOrGaussian(Img)
    % Implementasi filter median atau filter gaussian di sini
    % Preprocessing yang diperlukan pada gambar Img
    % PreprocessedImg adalah gambar yang telah diproses
    preprocessedImg = Img;

% Fungsi untuk meningkatkan kontras dan kecerahan gambar
function enhancedImg = enhanceContrastAndBrightness(preprocessedImg)
    % Implementasi peningkatan kontras dan kecerahan di sini
    % EnhancedImg adalah gambar yang telah ditingkatkan kontras dan kecerahannya
    % Menggunakan konstanta untuk menentukan tingkat peningkatan kontras dan kecerahan
    contrastFactor = 1.5; % Faktor peningkatan kontras
    brightnessFactor = 50; % Faktor peningkatan kecerahan
    
    % Mengalikan gambar dengan faktor kontras
    enhancedImg = preprocessedImg * contrastFactor;
    
    % Menambahkan nilai kecerahan ke setiap piksel gambar
    enhancedImg = enhancedImg + brightnessFactor;
    
    % Memastikan nilai piksel tidak melebihi batas maksimum (255)
    enhancedImg(enhancedImg > 255) = 255;
%     enhancedImg = preprocessedImg;

% Fungsi untuk segmentasi daun dari latar belakang
function segmentedImg = leafSegmentation(enhancedImg)
    % Implementasi segmentasi di sini
    % SegmentedImg adalah gambar daun hasil segmentasi
    % Konversi gambar ke skala keabuan jika belum dalam bentuk tersebut
    grayImg = rgb2gray(enhancedImg);

    % Tentukan ambang batas menggunakan metode Otsu's thresholding
    threshold = graythresh(grayImg);

    % Segmentasi dengan thresholding
    binaryImg = imbinarize(grayImg, threshold);

    % Mendapatkan citra daun yang tersegmentasi
    segmentedImg = enhancedImg;
    segmentedImg(repmat(~binaryImg, [1, 1, 3])) = 0; % Set latar belakang menjadi hitam

    % Opsional: Lakukan operasi morfologi untuk memperbaiki hasil segmentasi jika diperlukan
    segmentedImg = imopen(segmentedImg, strel('disk', 3)); % Contoh operasi morfologi
%     segmentedImg = enhancedImg;

% Fungsi untuk ekstraksi fitur HSV
function hsvFeatures = extractHSVFeatures(segmentedImg)
    % Implementasi ekstraksi fitur HSV di sini
    % HsvFeatures adalah vektor fitur HSV
    % Convert the segmented image to HSV color space
    hsvImg = rgb2hsv(segmentedImg);

    % Extract HSV features (example: using 3 features)
    hue = hsvImg(:,:,1);
    saturation = hsvImg(:,:,2);
    value = hsvImg(:,:,3);

    % Calculate the mean value of each channel
    meanHue = mean(hue(:));
    meanSaturation = mean(saturation(:));
    meanValue = mean(value(:));

    % Return the feature vector
    hsvFeatures = [meanHue, meanSaturation, meanValue];


% Fungsi untuk ekstraksi fitur GLCM
function glcmFeatures = extractGLCMFeatures(segmentedImg)
    % Implementasi ekstraksi fitur GLCM di sini
    % GlcmFeatures adalah vektor fitur GLCM
    % Convert the segmented image to grayscale
    grayImg = rgb2gray(segmentedImg);

    % Calculate the GLCM matrix and extract features
    glcm = graycomatrix(grayImg);
    stats = graycoprops(glcm, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});

    % Extract the feature values
    contrast = stats.Contrast;
    correlation = stats.Correlation;
    energy = stats.Energy;
    homogeneity = stats.Homogeneity;

    % Return the feature vector
    glcmFeatures = [contrast, correlation, energy, homogeneity];


% Fungsi untuk ekstraksi fitur bentuk
function shapeFeatures = extractShapeFeatures(segmentedImg)
    % Implementasi ekstraksi fitur bentuk di sini
    % ShapeFeatures adalah vektor fitur bentuk
    % Convert the segmented image to grayscale
    grayImg = rgb2gray(segmentedImg);

    % Threshold the grayscale image to obtain a binary image
    threshold = graythresh(grayImg);
    binaryImg = imbinarize(grayImg, threshold);

    % Calculate the region properties of the binary image
    stats = regionprops(binaryImg, 'Area', 'Perimeter', 'Eccentricity');

    % Extract the feature values
    area = stats.Area;
    perimeter = stats.Perimeter;
    eccentricity = stats.Eccentricity;

    % Return the feature vector
    shapeFeatures = [area, perimeter, eccentricity];

   
% --- Outputs from this function are returned to the command line.
function varargout = TRAINING_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Baca data dari file Excel
data = readtable('ciri_database_dataset-test-record.xlsx', 'ReadVariableNames', true, 'PreserveVariableNames', true);

% Ubah data menjadi cell array
ciri_database = table2cell(data);

% Ambil kolom fitur dari ciri_database
fitur = cell2mat(ciri_database(:, 1:end-1));

% Tambahkan kolom "Class" sebagai label
label = cell(size(fitur, 1), 1);
for i = 1:size(fitur, 1)
    % Misalnya, jika nilai pertama dalam vektor fitur lebih besar dari 0.5,
    % beri label 'daunjambuair', jika tidak beri label 'daunjambubiji'
    if fitur(i, 1) > 0.34
        label{i} = 'daunjambuair';
    else
        label{i} = 'daunjambubiji';
    end
end

% Tambahkan kolom "Class" ke dalam ciri_database
ciri_database_labeled = [ciri_database, label];

% Simpan ciri_database_labeled ke dalam file Excel
writetable(cell2table(ciri_database_labeled), 'ciri_database_dataset-test-record.xlsx', 'WriteVariableNames', false);
headers = {'Hue', 'Saturation', 'Value', 'Contrast', 'Correlation', 'Energy', 'Homogeneity', 'ShapeFeature1', 'ShapeFeature2', 'SizeFeature1', 'SizeFeature2', 'SizeFeature3', 'SizeFeature4', 'SizeFeature5','Class'};
xlswrite('ciri_database_dataset-test-record.xlsx', headers, 'Sheet1', 'A1');
xlswrite('ciri_database_dataset-test-record.xlsx', ciri_database_labeled, 'Sheet1', 'A2');

% Split data menjadi data training dan data testing
[trainData, testData, trainLabels, testLabels] = splitData(fitur, label, 0.7);

% Lakukan pelatihan KNN
knnModel = fitcknn(trainData, trainLabels, 'NumNeighbors', 5);

% Prediksi label untuk data testing
predictedLabels = predict(knnModel, testData);

% Hitung akurasi
accuracy = sum(strcmp(predictedLabels, testLabels)) / numel(testLabels) * 100;

% Tampilkan akurasi
s = msgbox('Labeling Data Berhasil', 'status');
msgbox(['Akurasi prediksi: ' num2str(accuracy) '%'], 'status');

% Fungsi untuk membagi data menjadi data training dan data testing
function [trainData, testData, trainLabels, testLabels] = splitData(data, labels, trainRatio)
    % Acak indeks data
    indices = randperm(size(data, 1));
    
    % Hitung jumlah data training berdasarkan trainRatio
    numTrain = floor(trainRatio * size(data, 1));
    
    % Bagi data menjadi data training dan data testing
    trainData = data(indices(1:numTrain), :);
    testData = data(indices(numTrain+1:end), :);
    trainLabels = labels(indices(1:numTrain));
    testLabels = labels(indices(numTrain+1:end));
    

