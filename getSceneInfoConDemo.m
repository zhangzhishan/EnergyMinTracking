function sceneInfo=getSceneInfoConDemo
% fill all necessary information about the
% scene into the sceneInfo struct
%
% Required:
%   detfile         detections file (.idl or .xml)
%   frameNums       frame numbers (eg. frameNums=1:107)
%   imgFolder       image folder
%   imgFileFormat   format for images (eg. frame_%04d.jpg)
%   targetSize      approx. size of targets (default: 5 on image, 350 in 3d)
%
% Required for 3D Tracking only
%   trackingArea    tracking area
%   camFile         camera calibration file (.xml PETS format)
%
% Optional:
%   gtFile          file with ground truth bounding boxes (.xml CVML)
%   initSolFile     initial solution (.xml or .mat)
%   targetAR        aspect ratio of targets on image
%   bgMask          mask to bleach out the background
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.


global opt
dbfolder='demo';
sceneInfo.detfile=fullfile(dbfolder,'det','PETS2009-S3MF1-c1-det.xml');
sceneInfo.frameNums=1:107;
sceneInfo.imgFolder=fullfile(dbfolder,'img',filesep);
sceneInfo.imgFileFormat='frame_%04d.jpg';

% image dimensions
[sceneInfo.imgHeight, sceneInfo.imgWidth, ~]= ...
    size(imread([sceneInfo.imgFolder sprintf(sceneInfo.imgFileFormat,sceneInfo.frameNums(1))]));


%% tracking area
% if we are tracking on the ground plane
% we need to explicitly secify the tracking area
% otherwise image = tracking area
if opt.track3d
     sceneInfo.trackingArea=[-14069.6, 4981.3, -14274.0, 1733.5];
else
     sceneInfo.trackingArea=[1 sceneInfo.imgWidth 1 sceneInfo.imgHeight];   % tracking area
end

%% camera
cameraconffile=[];
if opt.track3d
     cameraconffile=fullfile(dbfolder,'cam','View_001.xml');
end
sceneInfo.camFile=cameraconffile;

if ~isempty(sceneInfo.camFile)
    sceneInfo.camPar=parseCameraParameters(sceneInfo.camFile);
end


%% target size
sceneInfo.targetSize=20;                % target 'radius'
sceneInfo.targetSize=sceneInfo.imgWidth/30;
if opt.track3d, sceneInfo.targetSize=350; end

%% target aspect ratio
sceneInfo.targetAR=1/3;

%% ground truth
sceneInfo.gtFile='';
sceneInfo.gtFile=fullfile(dbfolder,'gt','PETS2009-S3MF1-c1.mat');

global gtInfo
sceneInfo.gtAvailable=0;
if ~isempty(sceneInfo.gtFile)
    sceneInfo.gtAvailable=1;
    % first determine the type
    [~, ~, fileext]=fileparts(sceneInfo.gtFile);
    
    if strcmpi(fileext,'.xml') % CVML
        gtInfo=parseGT(sceneInfo.gtFile);
    elseif strcmpi(fileext,'.mat')
        % check for the var gtInfo
        fileInfo=who('-file',sceneInfo.gtFile);
        varExists=0; cnt=0;
        while ~varExists && cnt<length(fileInfo)
            cnt=cnt+1;
            varExists=strcmp(fileInfo(cnt),'gtInfo');
        end
        
        if varExists
            load(sceneInfo.gtFile,'gtInfo');
        else
            warning('specified file does not contained correct ground truth');
            sceneInfo.gtAvailable=0;
        end
    end
    
    if opt.track3d
        if ~isfield(gtInfo,'Xgp') || ~isfield(gtInfo,'Ygp')
            [gtInfo.Xgp gtInfo.Ygp]=projectToGroundPlane(gtInfo.X, gtInfo.Y, sceneInfo);
        end
    end
    
    %     if strcmpi(fileext,'.xml'),     save(fullfile(pathtogt,[gtfile '.mat']),'gtInfo'); end
end

%% check
if opt.track3d
    if ~isfield(sceneInfo,'trackingArea')
        error('tracking area [minx maxx miny maxy] required for 3d tracking');
    elseif ~isfield(sceneInfo,'camFile')
        error('camera parameters required for 3d tracking');
    end
end

end