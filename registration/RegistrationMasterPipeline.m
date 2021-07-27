timerval = tic;
%% Initilize
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\mij.jar'
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\ij-1.52a.jar'
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\TurboRegHL_.jar'
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\MultiStackReg1.45_.jar'

%put in some identifying information
mouse = 'PK16';
date = '210719'; %YYMMDD format
run = 1;
ftype = 'sbx';
server = 'sweetness'; %nickname for server/drive name
fbase = 'PK16_210719_001'; %file name of the tif.frames folder
opttype = 'affine'; %'none' if using piezo, 'affine' if using optitune
refchannel = 2; %1 = red, 2 = green

fdir = pipe.lab.datedir(mouse,date,server);
path = pipe.lab.datapath(mouse,date,run,ftype,server);

[Nchan, Nx, Ny, Nz, Nt] = GetDimensions(path,fdir,fbase);

scale = 4;
chunksize = 20; %don't go over 20
Nchunks = round(Nt/chunksize);
proj_range = 1:Nz;
proj_type = 'mean'; % 'max', 'median', 'mean'

%% convert OIR to SBX (SKIP THIS IF RE-RUNNING)
if isempty(path)
    lineshift = ConvertOIR_SBX(mouse,date,run,fdir,fbase,Nx,Ny,Nz,Nt,Nchan,'lineshift',true);
    path = pipe.lab.datapath(mouse,date,run,ftype,server);
end
%% calculate optotune warping
tforms_optotune = CalculateOptotuneWarp(path, refchannel, scale, 'regtype', opttype, 'save', 'true');

%% DFT warp
shiftpath = strcat(pipe.lab.rundir(mouse,date,run,server),'.dftshifts');
DFT_warp_3D_2(path, shiftpath, refchannel, scale, Nchunks, tforms_optotune, 'reftype','mean');

%% make registered SBX file, and do zprojection
zproj_mean = MakeSBXall(path,shiftpath,'refchannel',refchannel);

savepath = strcat(pipe.lab.rundir(mouse,date,run,server),'_',proj_type,'_zproj.tif');
write2chanTiff(uint16(zproj_mean),savepath);
