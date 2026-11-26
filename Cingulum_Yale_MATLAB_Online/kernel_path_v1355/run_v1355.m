function run_v1355()
% V1355 original-only dormqr width-dispatch probe (source-DISCLOSED diagnostic).
% V1353 found genuine X\B departs from the blocked-dormqr model (block size 8) once there are
% 100 or more right-hand sides and 9 or more columns, while every dgemm product it uses is
% exact. This run compares X\B with dgeqp3 -> {dormqr, dorm2r, blocked dlarfb with block size
% 8, 16, 32, 64, dormqr with small workspaces} -> dtrtrs for 40..1,000 right-hand sides. Synthetic seeded inputs only. Reads no Rust forecast
% and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1355_ORIGINAL_ONLY_DORMQR_WIDTH_DISPATCH_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(f,'%s\n',jsonencode(prov));fclose(f);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1355.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
rng(135501,'twister');
labels={'dormqr','dorm2r','blk8','blk16','blk32','blk64','lw8','lw16','lw32'};
modes=[0 0;1 0;2 8;2 16;2 32;2 64;3 8;3 16;3 32];
rec=zeros(0,5+size(modes,1));
for m=[100 300 1000]
 for n=[9 12 16 17 24 32]
  for w=[40 41 42 43 44 47 48 49 50 56 63 64 65 80 96 100 127 128 129 200 256 257 500 1000]
   X=rand(m,n)-0.5;B=rand(m,w)-0.5;
   Z=X\B;
   r=[m n w numel(Z) 0];
   for q=1:size(modes,1)
    Zq=kp1355('solve',X,B,modes(q,1),modes(q,2));
    r(5+q)=sum(typecast(Z(:),'uint64')==typecast(Zq(:),'uint64'));
   end
   rec(end+1,:)=r; %#ok<AGROW>
  end
 end
end
writematrix(rec,fullfile(outdir,'dispatch.csv'));
fprintf(logf,'columns: m n w words 0 %s\n',strjoin(labels,' '));
for i=1:size(rec,1);fprintf(logf,'%s\n',num2str(rec(i,:)));end
end
