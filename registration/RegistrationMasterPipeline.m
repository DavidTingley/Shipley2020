timerval = tic;
%% Initilize
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\mij.jar'
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\ij-1.52a.jar'
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\TurboRegHL_.jar'
javaaddpath 'D:\User\tingley\Dropbox\code\Shipley2020\MultiStackReg1.45_.jar'

javaaddpath 'D:\User Folders\dtingley\Dropbox\code\Shipley2020\mij.jar'
javaaddpath 'D:\User Folders\dtingley\Dropbox\code\Shipley2020\ij-1.52a.jar'
javaaddpath 'D:\User Folders\dtingley\Dropbox\code\Shipley2020\TurboRegHL_.jar'
javaaddpath 'D:\User Folders\dtingley\Dropbox\code\Shipley2020\MultiStackReg1.45_.jar'

javaaddpath 'D:\User Folders\tingley\Dropbox\code\Shipley2020\mij.jar'
javaaddpath 'D:\User Folders\tingley\Dropbox\code\Shipley2020\ij-1.52a.jar'
javaaddpath 'D:\User Folders\tingley\Dropbox\code\Shipley2020\TurboRegHL_.jar'
javaaddpath 'D:\User Folders\tingley\Dropbox\code\Shipley2020\MultiStackReg1.45_.jar'

javaaddpath 'D:\Users\tingley\Dropbox\code\Shipley2020\mij.jar'
javaaddpath 'D:\Users\tingley\Dropbox\code\Shipley2020\ij-1.52a.jar'
javaaddpath 'D:\Users\tingley\Dropbox\code\Shipley2020\TurboRegHL_.jar'
javaaddpath 'D:\Users\tingley\Dropbox\code\Shipley2020\MultiStackReg1.45_.jar'



%put in some identifying information
mouse = 'DT1';
date = '100'; %YYMMDD format
run = 1:77;
ftype = 'sbx';
server = 'nasquatch'; %nickname for server/drive name
fbase = 'DT1_100'; %file name of the tif.frames folder
opttype = 'affine'; %'none' if using piezo, 'affine' if using optitune
refchannel = 1; %1 = red, 2 = green

folder = pwd;%pipe.lab.rundir(mouse, date, run(1), server);



if length(run) > 1
   % need to merge all
%    mkdir aligned
   
   for r = 1:length(run)
       temp = pipe.io.read_sbx([mouse '_' date '_' num2str(run(r),'%0.3d') '.' ftype],1,-1,1,[]);
       info = pipe.io.read_sbxinfo([mouse '_' date '_' num2str(run(r),'%0.3d') '.' ftype]);
       completeStacks = floor(size(temp,3)/info.otlevels);
       temp = temp(:,:,1:completeStacks * info.otlevels);
       
       if r == 1
        rw = pipe.io.RegWriter([folder '\' mouse '_' date '_merge.' ftype], info, 'sbx', true,'w');      
       else
        rw = pipe.io.RegWriter([folder '\' mouse '_' date '_merge.' ftype], info, 'sbx', true,'a');
       end
       rw.write(temp);
       rw.close();
       
%        fclose(info.fid)
       nFrames(r) = size(temp,3);
%        movefile([mouse '_' date '_' num2str(run(r),'%0.3d') '.*' ],['runs_split\'])
   end
   
   % write new info file??
   run = 'merge';
   info.nFrames = sum(nFrames);
   info.wells = nFrames;
   filepath = [folder '\' mouse '_' date '_merge.' ftype];%pipe.lab.datapath(mouse,date,run,ftype,server);

   save([folder '\' mouse '_' date '_merge.mat'] ,'info')
else
    filepath = [folder '\' mouse '_' date '_' num2str(run,'%0.3d'), '.' ftype];%pipe.lab.datapath(mouse,date,run,ftype,server);

end

fdir = pipe.lab.datedir(mouse,date,server);

[Nchan, Nx, Ny, Nz, Nt] = GetDimensions(filepath,fdir,fbase);

scale = 3;
chunksize = 200; %don't go over 20
Nchunks = round(Nt/chunksize);
proj_range = 1:Nz;
proj_type = 'mean'; % 'max', 'median', 'mean'

%% convert OIR to SBX (SKIP THIS IF RE-RUNNING)
if isempty(filepath)
    lineshift = ConvertOIR_SBX(mouse,date,run,fdir,fbase,Nx,Ny,Nz,Nt,Nchan,'lineshift',true);
    filepath = pipe.lab.datafilepath(mouse,date,run,ftype,server);
end
%% calculate optotune warping
tforms_optotune = CalculateOptotuneWarp(filepath, refchannel, scale, 'regtype', opttype, 'save', 'true');

%% DFT warp
% shiftfilepath = strcat(pipe.lab.rundir(mouse,date,run,server),'.dftshifts');
shiftfilepath = [folder '\' mouse '_' date '_merge.dftshifts.mat'];
DFT_warp_3D_2(filepath, shiftfilepath, refchannel, scale, Nchunks, tforms_optotune, 'reftype','mean');

%% make registered SBX file, and do zprojection
zproj_mean = MakeSBXall([filepath],shiftfilepath,'refchannel',refchannel,'fileFmt','sbx');

savefilepath = strcat(pipe.lab.rundir(mouse,date,run,server),'_',proj_type,'_zproj.tif');
write2chanTiff(uint16(zproj_mean),savefilepath);

% delete merge non-aligned file
delete([folder '\' mouse '_' date '_merge.' ftype])
