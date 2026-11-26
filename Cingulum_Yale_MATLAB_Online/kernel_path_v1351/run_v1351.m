function run_v1351()
% V1351 original-only large-row dgemm summation-order probe (source-DISCLOSED diagnostic).
% V1350 found genuine X\B exact in the Rust model up to 1,100 rows except when the problem
% has 9 or more columns (blocked dormqr), 13 or more right-hand sides and 400 or more rows.
% The suspect is the matrix product inside blocked dlarfb when its inner sum is long. This
% run (A) checks that X\B is still dgeqp3 -> dormqr -> dtrtrs at 300..2,000 rows and that
% dormqr equals blocked dlarft + dlarfb built on the public dgemm; (B, C, D) reads the
% summation trees of dgemm('T','N') (W += C2'*V2, inner length L) and dgemm('N','T')
% (C2 -= V2*W', inner length k) at dlarfb shapes up to L = 2,000 with FPRev masks; (E) dumps
% both products on seeded random data with dlarfb-like strides and alignment, to decide FMA;
% (F) records genuine X\B for 400..2,000 rows with 9..40 right-hand sides (to find the exact
% width threshold) and (G) genuine robustfit at 1,500 and 2,000 rows, in the V1350
% containers. Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1351_ORIGINAL_ONLY_LARGE_ROW_DGEMM_ORDER_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1351.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
fprintf(logf,'mex ok\n');
warning('off','backtrace');
failed=false;tStart=tic;

% ---------------- A. X\B chain and dormqr against the public-dgemm reference ----------------
try
rng(135101,'twister');
rec=zeros(0,9);
for m=[300 400 513 1000 2000]
 for n=[9 16 17 32]
  for w=[9 12 13 40]
   X=rand(m,n)-0.5;B=rand(m,w)-0.5;
   Z=X\B;
   o=kp1351('chain',X,B);
   Zg=o(1:n,1:w);Q1=o(:,w+1:2*w);Q2=o(:,2*w+1:3*w);Q3=o(:,3*w+1:4*w);
   rec(end+1,:)=[m n w numel(Z) sum(bits(Z)==bits(Zg)) numel(Q1) sum(bits(Q1)==bits(Q2)) sum(bits(Q1)==bits(Q3)) sum(bits(Q2)==bits(Q3))]; %#ok<AGROW>
  end
 end
end
writematrix(rec,fullfile(outdir,'chain.csv'));
fprintf(logf,'A chain: X\\B==chain %d/%d words, dormqr==MKL blocked %d/%d, dormqr==public-dgemm ref %d/%d t=%.1f\n', ...
 sum(rec(:,5)),sum(rec(:,4)),sum(rec(:,7)),sum(rec(:,6)),sum(rec(:,8)),sum(rec(:,6)),toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B..D. summation trees ----------------
% trees.bin: 'CPMTR001', then records of int32: section (1 full tree, 2 anchor rows), op (0 TN,
% 1 NT), w, k, L, ldc, ldv, offc, offv, na, anchors(na), len, payload(len). Payload as kp1351
% returns it: nuniq, (len, data)*, nout, ids(nout), extra (tree-consistency failures).
tf=fopen(fullfile(outdir,'trees.bin'),'w','ieee-le');assert(tf>0);
fwrite(tf,'CPMTR001','char');
try
cfg=[];
for L=[258 300 384 400 450 513]
 for w=[9 12 13 24 40]
  cfg(end+1,:)=[0 w 8 L L L 0 0]; %#ok<AGROW>
 end
end
cfg=[cfg;0 13 8 400 437 437 5 3;0 40 8 400 437 437 5 3;0 13 8 513 600 521 7 1];
cfg=[cfg;0 13 1 400 400 400 0 0;0 13 3 400 400 400 0 0;0 13 5 400 400 400 0 0;0 40 5 400 400 400 0 0];
cfg=[cfg;0 13 8 1000 1000 1000 0 0];
for i=1:size(cfg,1)
 c=cfg(i,:);
 p=kp1351('tree',c(1),c(2),c(3),c(4),c(5),c(6),c(7),c(8));
 writeRec(tf,1,c,[],p);
 fprintf(logf,'B tree TN w=%d k=%d L=%d ld=%d/%d off=%d/%d uniq=%d bad=%d t=%.1f\n',c(2),c(3),c(4),c(5),c(6),c(7),c(8),p(1),p(end),toc(tStart));
end
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
try
for L=[700 1000 1500 2000]
 for w=[13 24 40]
  an=unique([0 1 2 3 7 8 15 16 63 64 127 128 191 192 255 256 257 300 383 384 511 512 767 768 1023 1024 floor(L/2) L-2 L-1 L]);
  an=an(an<=L);
  c=[0 w 8 L L L 0 0];
  p=kp1351('anchor',c(1),c(2),c(3),c(4),c(5),c(6),c(7),c(8),an);
  writeRec(tf,2,c,an,p);
  fprintf(logf,'C anchor TN w=%d L=%d anchors=%d uniq=%d t=%.1f\n',w,L,numel(an),p(1),toc(tStart));
 end
end
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
try
for L=[300 400 1000 2000]
 for w=[9 12 13 24 40]
  for k=[8 5]
   c=[1 w k L L L 0 0];
   p=kp1351('tree',c(1),c(2),c(3),c(4),c(5),c(6),c(7),c(8));
   writeRec(tf,1,c,[],p);
   fprintf(logf,'D tree NT w=%d k=%d L=%d uniq=%d bad=%d t=%.1f\n',w,k,L,p(1),p(end),toc(tStart));
  end
 end
end
c=[1 40 8 1000 1013 1013 5 3];
p=kp1351('tree',c(1),c(2),c(3),c(4),c(5),c(6),c(7),c(8));writeRec(tf,1,c,[],p);
catch err
 failed=true;fprintf(logf,'SECTION D FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fclose(tf);

% ---------------- E. random-data products with dlarfb-like strides ----------------
% gemm_rand.bin: 'CPMGR001', u64 count; per case u64 op (0 TN, 1 NT), M, N, K, lda, cola,
% offA, ldb, colb, offB, ldc, colc, offC; then A, B, C before, C after (full ld arrays).
try
rng(135105,'twister');
f=fopen(fullfile(outdir,'gemm_rand.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMGR001','char');cnt=0;fwrite(f,uint64(0),'uint64');
for L=[300 400 513 1000 2000]
 for w=[9 12 13 24 40]
  for k=[8 5]
   if k==5&&~(w==13||w==40);continue;end
   ld=L+13;
   % TN: W(w-by-k) += C2(L-by-w)' * V2(L-by-k)
   A=rand(ld,w)-0.5;Bm=rand(ld,k)-0.5;C=rand(w,k)-0.5;
   Co=kp1351('gemmx','T','N',w,k,L,1,1,A,5,Bm,3,C,0);
   fwrite(f,uint64([0 w k L ld w 5 ld k 3 w k 0]),'uint64');
   fwrite(f,A(:),'double');fwrite(f,Bm(:),'double');fwrite(f,C(:),'double');fwrite(f,Co(:),'double');cnt=cnt+1;
   % NT: C2(L-by-w) -= V2(L-by-k) * W(w-by-k)'
   A=rand(ld,k)-0.5;Bm=rand(w,k)-0.5;C=rand(ld,w)-0.5;
   Co=kp1351('gemmx','N','T',L,w,k,-1,1,A,3,Bm,0,C,5);
   fwrite(f,uint64([1 L w k ld k 3 w k 0 ld w 5]),'uint64');
   fwrite(f,A(:),'double');fwrite(f,Bm(:),'double');fwrite(f,C(:),'double');fwrite(f,Co(:),'double');cnt=cnt+1;
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
fprintf(logf,'E random products %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION E FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- F. genuine X\B, 400..2,000 rows, 9..40 right-hand sides ----------------
% Container CPMXB001 exactly as V1350: magic, u64 count; per problem u64 m, n, w, kind, rank;
% then X, B, X\B, R of [Q,R,E]=qr(X,0), E (as doubles). Column-major.
try
rng(135106,'twister');
f=fopen(fullfile(outdir,'mldivide.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMXB001','char');cnt=0;fwrite(f,uint64(0),'uint64');
rec=zeros(0,6);
for m=[400 1000 2000]
 for n=[9 16 32]
  for w=[9 10 11 12 13 16 24 40]
   for kind=0:1
    if kind==1&&~(w==13||w==40);continue;end
    X=rand(m,n)-0.5;B=rand(m,w)-0.5;
    if kind==1;X(:,n)=X(:,1)+X(:,2);end
    lastwarn('');
    Z=X\B;
    [~,R,E]=qr(X,0);
    [wm,wid]=lastwarn;
    rk=n;
    if strcmp(wid,'MATLAB:rankDeficientMatrix');tk=regexp(wm,'rank = (\d+)','tokens','once');rk=n-1;if ~isempty(tk);rk=str2double(tk{1});end;end
    fwrite(f,uint64([m n w kind rk]),'uint64');
    fwrite(f,X(:),'double');fwrite(f,B(:),'double');fwrite(f,Z(:),'double');fwrite(f,R(:),'double');fwrite(f,double(E(:)),'double');
    cnt=cnt+1;rec(end+1,:)=[m n w kind rk numel(Z)]; %#ok<AGROW>
   end
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
writematrix(rec,fullfile(outdir,'mldivide_index.csv'));
fprintf(logf,'F X\\B problems %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION F FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- G. genuine robustfit at 1,500 and 2,000 rows ----------------
% Container CPMRFT01 exactly as V1350.
try
rng(135107,'twister');
fields={'ols_s','robust_s','mad_s','s','resid','rstud','se','covb','coeffcorr','t','p','w','Qy','R','dfe','h','Rtol'};
f=fopen(fullfile(outdir,'robustfit.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMRFT01','char');cnt=0;fwrite(f,uint64(0),'uint64');
rec=zeros(0,5);
for m=[1500 2000]
 for k=[1 2 8 20 31]
  for fam=0:1
   X=randn(m,k);beta=randn(k,1);e=randn(m,1);
   if fam==1
    o=rand(m,1)<0.1;e(o)=e(o)*15;
    if k>=3;X(:,k)=X(:,1)-2*X(:,2);end
   end
   y=1+X*beta+0.5*e;
   lastwarn('');
   [b,s]=robustfit(X,y);
   [~,wid]=lastwarn;
   p=k+1;rd=double(m-s.dfe<p);
   lim=double(strcmp(wid,'stats:statrobustfit:IterationLimit'));
   fwrite(f,uint64([m k rd+2*lim+4]),'uint64');
   fwrite(f,X(:),'double');fwrite(f,y(:),'double');fwrite(f,b(:),'double');
   for q=1:numel(fields);v=double(s.(fields{q}));fwrite(f,v(:),'double');end
   cnt=cnt+1;rec(end+1,:)=[m k fam m-s.dfe lim]; %#ok<AGROW>
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
writematrix(rec,fullfile(outdir,'robustfit_index.csv'));
fprintf(logf,'G robustfit cohorts %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION G FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1351 section failed; see out/log.txt');
end

function b=bits(x)
b=typecast(x(:),'uint64');
end

function writeRec(f,section,c,an,p)
fwrite(f,int32([section c numel(an)]),'int32');
if ~isempty(an);fwrite(f,int32(an),'int32');end
fwrite(f,int32(numel(p)),'int32');fwrite(f,int32(p),'int32');
end

function writeJson(path,value)
f=fopen(path,'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(value));
fclose(f);
end
