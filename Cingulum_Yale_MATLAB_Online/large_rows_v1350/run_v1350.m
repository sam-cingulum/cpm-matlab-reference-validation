function run_v1350()
% V1350 original-only large-row scan (source-DISCLOSED diagnostic).
% The X\B and robustfit models were measured and certified up to 130 rows. Research cohorts
% need at least 1,000. This run records genuine MATLAB X\B (with R and the pivot order of
% qr(X,0)) and robustfit (b and all 17 stats fields, and its warnings) for rows 131..1100 and
% 1..32 coefficients, so the Rust model can be scored against them and the first kernel that
% changes can be found. Synthetic seeded inputs only. No MEX. Reads no Rust forecast and no
% earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1350_ORIGINAL_ONLY_LARGE_ROW_SCAN_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
warning('off','backtrace');
failed=false;tStart=tic;
ms=[131 200 256 257 400 512 513 768 1000 1024 1025 1100];

% ---------------- A. X\B ----------------
% Container CPMXB001: magic, u64 count; per problem u64 m, n, w, kind, rank; then X (m*n),
% B (m*w), X\B (n*w), R of [Q,R,E]=qr(X,0) (n*n), E (n, as doubles). Column-major.
try
rng(135001,'twister');
ns=[1 2 3 5 8 9 16 17 31 32];ws=[1 2 3 5 8 13 40];
f=fopen(fullfile(outdir,'mldivide.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMXB001','char');cnt=0;fwrite(f,uint64(0),'uint64');
rec=zeros(0,6);
for m=ms
 for n=ns
  for kind=0:1
   w=ws(1+mod(cnt,numel(ws)));
   X=rand(m,n)-0.5;B=rand(m,w)-0.5;
   if kind==1&&n>=3
    X(:,n)=X(:,1)+X(:,2);   % rank deficient by one
   elseif kind==1
    X=X.*(1+1e3*(rand(m,1)<0.02));  % a few high-leverage rows
   end
   lastwarn('');
   Z=X\B;
   [~,R,E]=qr(X,0);
   [~,wid]=lastwarn;
   rk=n-double(strcmp(wid,'MATLAB:rankDeficientMatrix'));
   if strcmp(wid,'MATLAB:rankDeficientMatrix');[wm,~]=lastwarn;tk=regexp(wm,'rank = (\d+)','tokens','once');if ~isempty(tk);rk=str2double(tk{1});end;end
   fwrite(f,uint64([m n w kind rk]),'uint64');
   fwrite(f,X(:),'double');fwrite(f,B(:),'double');fwrite(f,Z(:),'double');fwrite(f,R(:),'double');fwrite(f,double(E(:)),'double');
   cnt=cnt+1;rec(end+1,:)=[m n w kind rk numel(Z)]; %#ok<AGROW>
  end
 end
end
fseek(f,8,'bof');fwrite(f,uint64(cnt),'uint64');fclose(f);
writematrix(rec,fullfile(outdir,'mldivide_index.csv'));
fprintf(logf,'A X\\B problems %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. robustfit ----------------
% Container CPMRFT01 (as the Rust fixture parser reads it): magic, u64 count; per cohort u64
% n, k, flags (bit 0 rank-deficient warning, bit 1 iteration-limit warning, bit 2 flags
% known), X (n*k), y (n), b (k+1), then ols_s robust_s mad_s s resid rstud se covb coeffcorr
% t p w Qy R dfe h Rtol.
try
rng(135002,'twister');
ks=[1 2 3 5 8 13 20 31];
fields={'ols_s','robust_s','mad_s','s','resid','rstud','se','covb','coeffcorr','t','p','w','Qy','R','dfe','h','Rtol'};
f=fopen(fullfile(outdir,'robustfit.bin'),'w','ieee-le');assert(f>0);
fwrite(f,'CPMRFT01','char');cnt=0;fwrite(f,uint64(0),'uint64');
rec=zeros(0,5);
for m=ms
 for k=ks
  for fam=0:1
   X=randn(m,k);beta=randn(k,1);
   e=randn(m,1);
   if fam==1
    o=rand(m,1)<0.1;e(o)=e(o)*15;          % gross outliers
    if k>=3;X(:,k)=X(:,1)-2*X(:,2);end     % rank deficient
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
fprintf(logf,'B robustfit cohorts %d t=%.1f\n',cnt,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1350 section failed; see out/log.txt');
end

function writeJson(path,value)
f=fopen(path,'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(value));
fclose(f);
end
