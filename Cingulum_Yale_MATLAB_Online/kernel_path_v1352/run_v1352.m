function run_v1352()
% V1352 original-only dgemm block-seam probe (source-DISCLOSED diagnostic).
% V1351 read MKL's dgemm('T','N') summation trees inside dlarfb: the columns after the last
% full 12-column tile split the inner sum into blocks once it is long (two halves at L = 258..512,
% 256-row blocks above). This run reads full trees at the seams that V1351 did not cover
% (L = 248..262, 511..514, 767..770, 1023..1026) with the unchanged V1351 gateway, plus seeded
% random products at the same lengths. Synthetic inputs only. Reads no Rust forecast and no
% earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
src=fullfile(fileparts(root),'kernel_path_v1351','kp1351.c');
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1352_ORIGINAL_ONLY_DGEMM_BLOCK_SEAM_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
mex('-R2018a','-silent','-outdir',outdir,src,'-lmwblas','-lmwlapack');
addpath(outdir);
fprintf(logf,'mex ok\n');
failed=false;tStart=tic;
Ls=[248:262 511:514 767:770 1023:1026];
tf=fopen(fullfile(outdir,'trees.bin'),'w','ieee-le');assert(tf>0);
fwrite(tf,'CPMTR001','char');
try
for L=Ls
 c=[0 13 8 L L L 0 0];
 p=kp1351('tree',c(1),c(2),c(3),c(4),c(5),c(6),c(7),c(8));
 fwrite(tf,int32([1 c 0]),'int32');fwrite(tf,int32(numel(p)),'int32');fwrite(tf,int32(p),'int32');
 fprintf(logf,'tree TN w=13 k=8 L=%d uniq=%d bad=%d t=%.1f\n',L,p(1),p(end),toc(tStart));
end
catch err
 failed=true;fprintf(logf,'TREES FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fclose(tf);
try
rng(135201,'twister');
f=fopen(fullfile(outdir,'gemm_rand.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMGR001','char');cnt=0;fwrite(f,uint64(0),'uint64');
for L=Ls
 for w=[13 40]
  ld=L+13;k=8;
  A=rand(ld,w)-0.5;Bm=rand(ld,k)-0.5;C=rand(w,k)-0.5;
  Co=kp1351('gemmx','T','N',w,k,L,1,1,A,5,Bm,3,C,0);
  fwrite(f,uint64([0 w k L ld w 5 ld k 3 w k 0]),'uint64');
  fwrite(f,A(:),'double');fwrite(f,Bm(:),'double');fwrite(f,C(:),'double');fwrite(f,Co(:),'double');cnt=cnt+1;
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
fprintf(logf,'random products %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'RANDOM FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1352 section failed; see out/log.txt');
end

function writeJson(path,value)
f=fopen(path,'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(value));
fclose(f);
end
