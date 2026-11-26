function run_v1353()
% V1353 original-only wide right-hand-side probe (source-DISCLOSED diagnostic).
% CPM's covariate step regresses every edge at once: X\B with a few columns and tens of
% thousands of right-hand sides. V1310 and V1351 covered at most 40. This run records
% (A) dgemm('T','N') and dgemm('N','T') at dlarfb shapes with 48..3,000 columns through the
% unchanged V1351 gateway, and (B) genuine X\B with 41..5,000 right-hand sides at 100..1,000
% rows. Inputs are not stored: each case reseeds the twister (seed in the record) and draws
% rand(...)-0.5 in the order written below. Synthetic only. Reads no Rust forecast and no
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
prov=struct('classification','V1353_ORIGINAL_ONLY_WIDE_RHS_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
mex('-R2018a','-silent','-outdir',outdir,src,'-lmwblas','-lmwlapack');
addpath(outdir);
fprintf(logf,'mex ok\n');
failed=false;tStart=tic;

% ---------------- A. products, wide ----------------
% wide_gemm.bin 'CPMGW001', u64 count; per case u64 seed, op (0 TN, 1 NT), M, N, K, lda, cola,
% offA, ldb, colb, offB, ldc, colc, offC; then C after (ldc*colc). Inputs: rng(seed,'twister');
% A=rand(lda,cola)-0.5; B=rand(ldb,colb)-0.5; C=rand(ldc,colc)-0.5.
try
f=fopen(fullfile(outdir,'wide_gemm.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMGW001','char');cnt=0;fwrite(f,uint64(0),'uint64');seed=135300;
for L=[60 300 1000]
 for w=[48 100 257 1000 3000]
  for k=[8 5]
   seed=seed+1;ld=L+13;
   rng(seed,'twister');A=rand(ld,w)-0.5;Bm=rand(ld,k)-0.5;C=rand(w,k)-0.5;
   Co=kp1351('gemmx','T','N',w,k,L,1,1,A,5,Bm,3,C,0);
   fwrite(f,uint64([seed 0 w k L ld w 5 ld k 3 w k 0]),'uint64');fwrite(f,Co(:),'double');cnt=cnt+1;
   if L<=300&&(w==100||w==1000)
    seed=seed+1;
    rng(seed,'twister');A=rand(ld,k)-0.5;Bm=rand(w,k)-0.5;C=rand(ld,w)-0.5;
    Co=kp1351('gemmx','N','T',L,w,k,-1,1,A,3,Bm,0,C,5);
    fwrite(f,uint64([seed 1 L w k ld k 3 w k 0 ld w 5]),'uint64');fwrite(f,Co(:),'double');cnt=cnt+1;
   end
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
fprintf(logf,'A products %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. genuine X\B, wide ----------------
% wide_xb.bin 'CPMXW001', u64 count; per problem u64 seed, m, n, w, kind, rank; then X\B (n*w).
% Inputs: rng(seed,'twister'); X=rand(m,n)-0.5; B=rand(m,w)-0.5; kind 1: X(:,n)=X(:,1)+X(:,2).
try
f=fopen(fullfile(outdir,'wide_xb.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMXW001','char');cnt=0;fwrite(f,uint64(0),'uint64');seed=135400;
rec=zeros(0,6);
for m=[100 300 1000]
 for n=[2 4 8 9 16]
  for w=[41 100 1000 5000]
   for kind=0:1
    if kind==1&&~(n>=3&&w==1000);continue;end
    seed=seed+1;
    rng(seed,'twister');X=rand(m,n)-0.5;B=rand(m,w)-0.5;
    if kind==1;X(:,n)=X(:,1)+X(:,2);end
    lastwarn('');
    Z=X\B;
    [wm,wid]=lastwarn;rk=n;
    if strcmp(wid,'MATLAB:rankDeficientMatrix');tk=regexp(wm,'rank = (\d+)','tokens','once');rk=n-1;if ~isempty(tk);rk=str2double(tk{1});end;end
    fwrite(f,uint64([seed m n w kind rk]),'uint64');fwrite(f,Z(:),'double');
    cnt=cnt+1;rec(end+1,:)=[seed m n w kind rk]; %#ok<AGROW>
   end
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
writematrix(rec,fullfile(outdir,'wide_xb_index.csv'));
% the generator check: the first draws of the first seed, so a scorer can confirm it
rng(135401,'twister');g=rand(1,16);
f=fopen(fullfile(outdir,'twister_check.bin'),'w','ieee-le');fwrite(f,g,'double');fclose(f);
fprintf(logf,'B X\\B problems %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1353 section failed; see out/log.txt');
end

function writeJson(path,value)
f=fopen(path,'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(value));
fclose(f);
end
