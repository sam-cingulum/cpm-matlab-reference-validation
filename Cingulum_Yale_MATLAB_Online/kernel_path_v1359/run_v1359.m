function run_v1359()
% V1359 original-only dtrmm and block-16 dgemm probe (source-DISCLOSED diagnostic).
% V1356 found dormqr's block-16 dlarfb departs from the Rust model while its dlarft and every
% dgemm('T','N') summation tree agree. dlarfb also calls dtrmm three times and dgemm('N','T').
% This run records (A) FPRev summation trees of dtrmm('R', ...) in the three forms dlarfb
% uses, (B) seeded random dtrmm products, and (C) seeded random dgemm products at the block-16
% and block-32 dlarfb shapes, including a one-column panel whose workspace keeps the leading
% dimension of the whole width. Synthetic inputs only. Reads no Rust forecast and no earlier
% MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1359_ORIGINAL_ONLY_DTRMM_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(f,'%s\n',jsonencode(prov));fclose(f);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1359.c'),'-lmwblas');
mex('-R2018a','-silent','-outdir',outdir,fullfile(fileparts(root),'kernel_path_v1351','kp1351.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
fprintf(logf,'mex ok\n');
failed=false;tStart=tic;
forms={'L','N','U';'U','N','N';'L','T','U'};

% ---------------- A. dtrmm trees ----------------
% trmm_trees.bin 'CPMTT001'; per record int32 [form m n], int32 len, then the gateway output.
try
f=fopen(fullfile(outdir,'trmm_trees.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMTT001','char');
for q=1:3
 for n=[8 9 12 16 24 32]
  for m=[1 2 3 5 13 65 100 256]
   p=kp1359('trmmtree',forms{q,1},forms{q,2},forms{q,3},m,n);
   fwrite(f,int32([q-1 m n]),'int32');fwrite(f,int32(numel(p)),'int32');fwrite(f,int32(p),'int32');
   fprintf(logf,'A tree %s%s%s m=%d n=%d uniq=%d bad=%d t=%.1f\n',forms{q,:},m,n,p(1),p(end),toc(tStart));
  end
 end
end
fclose(f);
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. random dtrmm ----------------
% trmm_rand.bin 'CPMTX001', u64 count; per case u64 seed, form, m, n; then W after (m*n).
% Inputs: rng(seed,'twister'); M=rand(n,n)-0.5; W=rand(m,n)-0.5.
try
f=fopen(fullfile(outdir,'trmm_rand.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMTX001','char');cnt=0;fwrite(f,uint64(0),'uint64');seed=135900;
for q=1:3
 for n=[8 9 12 16 17 24 32]
  for m=[1 2 3 5 13 65 100 256 257]
   seed=seed+1;rng(seed,'twister');M=rand(n,n)-0.5;W=rand(m,n)-0.5;
   Wo=kp1359('trmmx',forms{q,1},forms{q,2},forms{q,3},M,W);
   fwrite(f,uint64([seed q-1 m n]),'uint64');fwrite(f,Wo(:),'double');cnt=cnt+1;
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
fprintf(logf,'B random trmm %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- C. random dgemm at dlarfb shapes ----------------
% gemm_rand.bin 'CPMGW001' exactly as V1353: u64 count; per case u64 seed, op (0 TN, 1 NT),
% M, N, K, lda, cola, offA, ldb, colb, offB, ldc, colc, offC; then C after (ldc*colc).
% Inputs: rng(seed,'twister'); A=rand(lda,cola)-0.5; B=rand(ldb,colb)-0.5; C=rand(ldc,colc)-0.5.
try
f=fopen(fullfile(outdir,'gemm_rand.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMGW001','char');cnt=0;fwrite(f,uint64(0),'uint64');seed=135950;
for k=[8 16 24 32]
 % NT: C2(L-by-w) -= V2(L-by-k) * W(w-by-k)', W with leading dimension ldw >= w
 for L=[11 12 13 24 84 284]
  for wl=[1 1;2 2;3 3;4 4;5 5;8 8;65 65;100 100;256 256;1 257;44 300]'
   w=wl(1);ldw=wl(2);seed=seed+1;
   rng(seed,'twister');A=rand(L,k)-0.5;Bm=rand(ldw,k)-0.5;C=rand(L,w)-0.5;
   Co=kp1351('gemmx','N','T',L,w,k,-1,1,A,0,Bm,0,C,0);
   fwrite(f,uint64([seed 1 L w k L k 0 ldw k 0 L w 0]),'uint64');fwrite(f,Co(:),'double');cnt=cnt+1;
  end
 end
 % TN: W(w-by-k, ld ldw) += C2'(L-by-w) * V2(L-by-k)
 for L=[32 84 284]
  for wl=[1 1;2 2;5 5;13 13;65 65;100 100;256 256;1 257;44 300]'
   w=wl(1);ldw=wl(2);seed=seed+1;
   rng(seed,'twister');A=rand(L,w)-0.5;Bm=rand(L,k)-0.5;C=rand(ldw,k)-0.5;
   Co=kp1351('gemmx','T','N',w,k,L,1,1,A,0,Bm,0,C,0);
   fwrite(f,uint64([seed 0 w k L L w 0 L k 0 ldw k 0]),'uint64');fwrite(f,Co(:),'double');cnt=cnt+1;
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
fprintf(logf,'C random products %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1359 section failed; see out/log.txt');
end
