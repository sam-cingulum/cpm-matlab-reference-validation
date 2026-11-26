function run_v1361()
% V1361 original-only dtrmm summation-tree probe with a strided workspace (source-DISCLOSED
% diagnostic). V1360 showed dtrmm('R', ...) on ONE row whose leading dimension exceeds 1 (the
% one-column last panel of dormqr's dlarfb) follows neither the one-row trees nor the general
% ones once there are 9 or more columns. This run reads its FPRev summation trees in the two
% forms dlarfb uses first (L,N,U = W*V1 and U,N,N = W*T), for 8..16, 24 and 32 columns and
% leading dimensions 1, 2, 257 (one row) and 257 (two rows). Synthetic inputs only. Reads no
% Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1361_ORIGINAL_ONLY_DTRMM_LD_TREE_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(f,'%s\n',jsonencode(prov));fclose(f);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1361.c'),'-lmwblas');
addpath(outdir);
fprintf(logf,'mex ok\n');tStart=tic;
forms={'L','N','U';'U','N','N'};
% trmm_ld_trees.bin 'CPMTT002'; per record int32 [form m n ldb], int32 len, then the gateway output.
f=fopen(fullfile(outdir,'trmm_ld_trees.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMTT002','char');
shapes=[1 1;1 2;1 257;2 257];
for q=1:2
 for n=[8 9 10 11 12 13 14 15 16 24 32]
  for s=1:size(shapes,1)
   m=shapes(s,1);ld=shapes(s,2);
   p=kp1361('trmmtree',forms{q,1},forms{q,2},forms{q,3},m,n,ld);
   fwrite(f,int32([q-1 m n ld]),'int32');fwrite(f,int32(numel(p)),'int32');fwrite(f,int32(p),'int32');
   fprintf(logf,'tree %s%s%s m=%d n=%d ld=%d uniq=%d bad=%d t=%.1f\n',forms{q,:},m,n,ld,p(1),p(end),toc(tStart));
  end
 end
end
fclose(f);
end
