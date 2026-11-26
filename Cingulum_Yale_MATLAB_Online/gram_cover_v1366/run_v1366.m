function run_v1366()
% V1366 source-disclosed diagnostic (not evidence for any certificate). V1365 fitted a model of
% MATLAB's Z'*Z (MKL syrk: 64-row panels, 12-column tiles, an edge lane kernel and K blocks)
% from seven widths (65..400) and ten row counts. This run widens the data the model must match,
% on genuine MATLAB R2026b Update 1:
%   A1 Z'*Z for every width 2..140 at 300 and 800 rows
%   A2 Z'*Z at widths 66, 77 and 131 for 32 row counts from 257 to 3,000 (the K-block rule)
%   A3 Z'*Z at widths 401..1,199 (the covariance lasso runs to n-1 predictors)
%   B  genuine lasso(X,y,'Alpha',alpha,'Lambda',lambda) at new widths and row counts
% Z = rand(L,w) - 0.5 after rng(seed,'twister'); W is an unshared copy of Z and Z'*W is
% compared word for word with Z'*Z. Synthetic seeded inputs only. Reads no Rust forecast and
% no earlier MATLAB output. V12 SEALED.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1366_SOURCE_DISCLOSED_GRAM_COVERAGE_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'),'mkl_cbwr',getenv('MKL_CBWR'), ...
 'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(h,'%s\n',jsonencode(prov));fclose(h);
warning('off','backtrace');
failed=false;tStart=tic;

% ---------------- A. random Gram products ----------------
% gram.bin: 'CPMGU001'; per case u64 [case seed L w same], then the upper triangle of
% G = Z'*Z column by column (for j = 1..w, G(1:j,j)), then the upper triangle of G2 = Z'*W
% only when same < w*w (same counts equal words over the full matrices).
try
f=fopen(fullfile(outdir,'gram.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMGU001','char');
fc=fopen(fullfile(outdir,'gram_cases.csv'),'w');fprintf(fc,'case,seed,L,w,same,section\n');
shapes=zeros(0,3);
for L=[300 800];for w=2:140;shapes(end+1,:)=[L w 1];end;end %#ok<AGROW>
for w=[66 77 131]
 for L=[257 258 259 260 263 270 300 320 383 385 400 450 500 508 510 511 512 520 600 640 700 768 769 1000 1023 1024 1025 1536 2047 2048 2049 3000]
  shapes(end+1,:)=[L w 2]; %#ok<AGROW>
 end
end
for w=[401 449 450 451 513 514 515 577 642 643 771 899 1026 1027 1199];shapes(end+1,:)=[1200 w 3];end %#ok<AGROW>
shapes(end+1,:)=[900 450 3];shapes(end+1,:)=[900 771 3];shapes(end+1,:)=[2000 1199 3];
for c=0:size(shapes,1)-1
 L=shapes(c+1,1);w=shapes(c+1,2);
 seed=136600000+c;
 rng(seed,'twister');
 Z=rand(L,w)-0.5;
 G=Z'*Z;
 W=Z;W(1)=Z(1);
 G2=Z'*W;
 same=sum(typecast(G(:),'uint64')==typecast(G2(:),'uint64'));
 up=triu(true(w));
 fwrite(f,uint64([c seed L w same]),'uint64');fwrite(f,typecast(G(up),'uint64'),'uint64');
 if same<w*w;fwrite(f,typecast(G2(up),'uint64'),'uint64');end
 fprintf(fc,'%d,%d,%d,%d,%d,A%d\n',c,seed,L,w,same,shapes(c+1,3));
 if mod(c,20)==0||shapes(c+1,3)==3;fprintf(logf,'A case %d L=%d w=%d same=%d t=%.1f\n',c,L,w,same,toc(tStart));end
end
fclose(f);fclose(fc);
fprintf(logf,'A gram cases %d t=%.1f\n',size(shapes,1),toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. genuine lasso at new widths and row counts ----------------
% lasso.bin: 'CPMLS001' (the V1365 layout); per case u64 [case seed L w nlam warned], alpha,
% lambda (nlam words, as passed), y (L words), then B (w*nlam), Intercept, MSE, DF, Lambda
% (nlam each), twice. X = rand(L,w), then y = rand(L,1) + sum(X(:,1:5),2).
try
f=fopen(fullfile(outdir,'lasso.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMLS001','char');
fc=fopen(fullfile(outdir,'lasso_cases.csv'),'w');fprintf(fc,'case,seed,L,w,alpha,nlam,warn_id\n');
cfg={800,66,1e-9,0.1; 800,67,1e-9,0.1; 800,129,1e-9,0.1; 300,77,1e-9,0.1; 400,130,1e-9,0.1; ...
     1000,450,1e-9,0.1; 1100,515,1e-9,0.1; 1200,401,1e-6,[0.3 0.1 0.03]; 1200,771,1e-9,0.1; ...
     1200,1026,1e-9,0.1; 2000,131,1e-9,0.1; 700,10,1e-9,0.1; 900,11,1e-9,0.1; 600,63,1e-9,0.1};
for c=0:size(cfg,1)-1
 L=cfg{c+1,1};w=cfg{c+1,2};alpha=cfg{c+1,3};lam=cfg{c+1,4};
 seed=136620000+c;
 rng(seed,'twister');
 X=rand(L,w);y=rand(L,1)+sum(X(:,1:min(5,w)),2);
 out=[];wid='';
 for rep=1:2
  lastwarn('');
  [B,FI]=lasso(X,y,'Alpha',alpha,'Lambda',lam);
  [~,wid]=lastwarn;
  out=[out;B(:);FI.Intercept(:);FI.MSE(:);FI.DF(:);FI.Lambda(:)]; %#ok<AGROW>
 end
 nlam=numel(FI.Lambda);
 fwrite(f,uint64([c seed L w nlam ~isempty(wid)]),'uint64');
 fwrite(f,typecast([alpha;lam(:);y],'uint64'),'uint64');fwrite(f,typecast(out,'uint64'),'uint64');
 fprintf(fc,'%d,%d,%d,%d,%.17g,%d,%s\n',c,seed,L,w,alpha,nlam,wid);
 fprintf(logf,'B lasso L=%d w=%d alpha=%g nlam=%d warn=%s t=%.1f\n',L,w,alpha,nlam,wid,toc(tStart));
end
fclose(f);fclose(fc);
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1366 section failed; see out/log.txt');
end
