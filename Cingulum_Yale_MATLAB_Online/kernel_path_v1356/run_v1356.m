function run_v1356()
% V1356 original-only dormqr corner probe (source-DISCLOSED diagnostic).
% V1355 found MKL's dormqr uses block size 16 for 65..128 right-hand sides, and for 129 or
% more right-hand sides with fewer than 300 rows nothing it tried matched (block size 16 came
% within the last column at 257 right-hand sides). The Rust model refuses those corners. This
% run records what is needed to model them:
%  A. X\B against dormqr, dorm2r, blocked passes with block size 16 and 32, the same passes on
%     column panels of 128, 256 or 512 columns, and dormqr per column panel (dispatch.csv);
%  B. genuine X\B at the corners (wide_xb.bin, CPMXW001 as in V1353, inputs regenerated from
%     the seed in each record);
%  C. one dlarft + dlarfb stage with block size 16 or 32 (stage.bin);
%  D. dgemm summation trees at the block-16 and block-32 dlarfb shapes (trees.bin, unchanged
%     V1351 gateway).
% Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1356_ORIGINAL_ONLY_DORMQR_CORNER_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(f,'%s\n',jsonencode(prov));fclose(f);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1356.c'),'-lmwblas','-lmwlapack');
mex('-R2018a','-silent','-outdir',outdir,fullfile(fileparts(root),'kernel_path_v1351','kp1351.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
fprintf(logf,'mex ok\n');
failed=false;tStart=tic;

% ---------------- A. dispatch ----------------
try
rng(135601,'twister');
labels={'dormqr','dorm2r','blk16','blk32','pan16x128','pan16x256','pan16x512','pan32x256','ormqr128','ormqr256','ormqr512'};
modes=[0 0 0;1 0 0;2 16 0;2 32 0;4 16 128;4 16 256;4 16 512;4 32 256;5 0 128;5 0 256;5 0 512];
rec=zeros(0,5+size(modes,1));
for m=[48 64 100 150 200 250 256 257 280 299 300 301 400]
 for n=[12 17 24 32]
  for w=[65 100 128 129 200 256 257 300 384 512 513 1000]
   X=rand(m,n)-0.5;B=rand(m,w)-0.5;
   Z=X\B;
   r=[m n w numel(Z) 0];
   for q=1:size(modes,1)
    Zq=kp1356('solve',X,B,modes(q,1),modes(q,2),modes(q,3));
    r(5+q)=sum(typecast(Z(:),'uint64')==typecast(Zq(:),'uint64'));
   end
   rec(end+1,:)=r; %#ok<AGROW>
  end
 end
end
writematrix(rec,fullfile(outdir,'dispatch.csv'));
fprintf(logf,'A columns: m n w words 0 %s\n',strjoin(labels,' '));
for i=1:size(rec,1);fprintf(logf,'%s\n',num2str(rec(i,:)));end
fprintf(logf,'A dispatch %d t=%.1f\n',size(rec,1),toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. genuine X\B at the corners ----------------
% wide_xb.bin 'CPMXW001', u64 count; per problem u64 seed, m, n, w, kind, rank; then X\B (n*w).
% Inputs: rng(seed,'twister'); X=rand(m,n)-0.5; B=rand(m,w)-0.5; kind 1: X(:,n)=X(:,1)+X(:,2).
try
f=fopen(fullfile(outdir,'wide_xb.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMXW001','char');cnt=0;fwrite(f,uint64(0),'uint64');seed=135600;
shapes=zeros(0,4);
for m=[48 100 200 299 300 1000]
 for n=[17 24 32]
  for w=[65 76 100 128 129 200 256 257 300 513 1000 2000]
   shapes(end+1,:)=[m n w 0]; %#ok<AGROW>
   if w==100||w==300;shapes(end+1,:)=[m n w 1];end %#ok<AGROW>
  end
 end
end
for m=[100 299]
 for n=[9 12 16]
  for w=[129 257 1000]
   shapes(end+1,:)=[m n w 0]; %#ok<AGROW>
  end
 end
end
for i=1:size(shapes,1)
 m=shapes(i,1);n=shapes(i,2);w=shapes(i,3);kind=shapes(i,4);
 seed=seed+1;
 rng(seed,'twister');X=rand(m,n)-0.5;B=rand(m,w)-0.5;
 if kind==1;X(:,n)=X(:,1)+X(:,2);end
 lastwarn('');
 Z=X\B;
 [wm,wid]=lastwarn;rk=n;
 if strcmp(wid,'MATLAB:rankDeficientMatrix');tk=regexp(wm,'rank = (\d+)','tokens','once');rk=n-1;if ~isempty(tk);rk=str2double(tk{1});end;end
 fwrite(f,uint64([seed m n w kind rk]),'uint64');fwrite(f,Z(:),'double');
 cnt=cnt+1;
 if kind==1;fprintf(logf,'B warning %s | %s\n',wid,wm);end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
rng(135601,'twister');g=rand(1,16);
f=fopen(fullfile(outdir,'twister_check.bin'),'w','ieee-le');fwrite(f,g,'double');fclose(f);
fprintf(logf,'B X\\B problems %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- C. one blocked stage ----------------
% stage.bin 'CPMST001', u64 count; per case u64 seed, m, n, w, nb, len; then S (len doubles):
% tau (n), packed QR (m*n), jpvt (n), T (nb*nb, ld nb), C after the first dlarfb (m*w).
try
f=fopen(fullfile(outdir,'stage.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMST001','char');cnt=0;fwrite(f,uint64(0),'uint64');seed=135700;
cases=[100 24 100 16;300 32 100 16;100 17 65 16;1000 24 128 16;100 24 300 16;48 32 70 16;299 32 257 16;100 32 129 32;1000 32 300 32;100 16 100 16];
for i=1:size(cases,1)
 m=cases(i,1);n=cases(i,2);w=cases(i,3);nb=cases(i,4);
 seed=seed+1;rng(seed,'twister');X=rand(m,n)-0.5;B=rand(m,w)-0.5;
 S=kp1356('stage',X,B,nb);
 fwrite(f,uint64([seed m n w nb numel(S)]),'uint64');fwrite(f,S,'double');cnt=cnt+1;
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
fprintf(logf,'C stages %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- D. summation trees at block-16/32 shapes ----------------
tf=fopen(fullfile(outdir,'trees.bin'),'w','ieee-le');assert(tf>0);
fwrite(tf,'CPMTR001','char');
try
cfg=[0 65 16 60 60 60 0 0;0 100 16 60 60 60 0 0;0 128 16 100 100 100 0 0;0 100 16 250 250 250 0 0;
     0 257 16 60 60 60 0 0;0 100 13 60 60 60 0 0;0 100 32 60 60 60 0 0;0 24 16 60 60 60 0 0;0 13 16 60 60 60 0 0;
     1 100 16 60 60 60 0 0;1 100 32 60 60 60 0 0;1 65 16 100 100 100 0 0;1 257 16 60 60 60 0 0;
     1 128 16 300 300 300 0 0;1 13 16 60 60 60 0 0];
for i=1:size(cfg,1)
 c=cfg(i,:);
 p=kp1351('tree',c(1),c(2),c(3),c(4),c(5),c(6),c(7),c(8));
 writeRec(tf,1,c,[],p);
 fprintf(logf,'D tree op=%d w=%d k=%d L=%d uniq=%d bad=%d t=%.1f\n',c(1),c(2),c(3),c(4),p(1),p(end),toc(tStart));
end
catch err
 failed=true;fprintf(logf,'SECTION D FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fclose(tf);
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1356 section failed; see out/log.txt');
end

function writeRec(f,section,c,an,p)
fwrite(f,int32([section c numel(an)]),'int32');
if ~isempty(an);fwrite(f,int32(an),'int32');end
fwrite(f,int32(numel(p)),'int32');fwrite(f,int32(p),'int32');
end
