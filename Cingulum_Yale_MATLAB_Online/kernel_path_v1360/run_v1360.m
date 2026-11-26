function run_v1360()
% V1360 original-only dtrmm probe with a strided workspace (source-DISCLOSED diagnostic).
% After V1359, the block-16 dlarfb model reproduces every V1356 case except the one-column
% last panel (257 and 513 right-hand sides), whose dlarfb workspace keeps the leading
% dimension of the whole width. This run records seeded random dtrmm('R', ...) products in
% the two forms that differ (L,N,U = W*V1 and U,N,N = W*T) with leading dimensions larger than
% the row count, and every block size 8..16 (plus 24 and 32). Synthetic inputs only. Reads no
% Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1360_ORIGINAL_ONLY_DTRMM_LD_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(f,'%s\n',jsonencode(prov));fclose(f);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1360.c'),'-lmwblas');
addpath(outdir);
fprintf(logf,'mex ok\n');tStart=tic;
forms={'L','N','U';'U','N','N'};
% trmm_ld.bin 'CPMTL001', u64 count; per case u64 seed, form, m, n, ldb; then the first m rows
% of W after (m*n, column-major). Inputs: rng(seed,'twister'); M=rand(n,n)-0.5; W=rand(ldb,n)-0.5.
shapes=[1 1;1 2;1 257;1 513;2 257;3 257;5 257;13 257;65 257;256 257;13 13;32 32;65 65;100 100;256 256];
f=fopen(fullfile(outdir,'trmm_ld.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMTL001','char');cnt=0;fwrite(f,uint64(0),'uint64');seed=136000;
for q=1:2
 for n=[8 9 10 11 12 13 14 15 16 24 32]
  for s=1:size(shapes,1)
   m=shapes(s,1);ldb=shapes(s,2);reps=1;if m==1;reps=4;end
   for r=1:reps
    seed=seed+1;rng(seed,'twister');M=rand(n,n)-0.5;W=rand(ldb,n)-0.5;
    Wo=kp1360('trmmld',forms{q,1},forms{q,2},forms{q,3},M,W,m);
    fwrite(f,uint64([seed q-1 m n ldb]),'uint64');fwrite(f,Wo(:),'double');cnt=cnt+1;
   end
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
fprintf(logf,'trmm_ld %d cases t=%.1f\n',cnt,toc(tStart));
end
