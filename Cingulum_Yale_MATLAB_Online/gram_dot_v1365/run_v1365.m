function run_v1365()
% V1365 source-disclosed diagnostic (not evidence for any certificate). V1362 left six
% workspace-scale lasso fits open (covariance solver, alpha 1e-9/1e-6, 180..400 active
% predictors, 800..900 training rows). This run reads, on genuine MATLAB R2026b Update 1:
%   A  Z'*Z and Z'*W (W an unshared copy of Z) on twister data, Z = rand(L,w) - 0.5,
%      L = 256..2,000 rows, w = 65..400 columns (gram.bin)
%   B  FPRev anchor rows of the summation trees of Z'*Z at three shapes (trees.bin):
%      Z is all ones except row a = 2^40 and row b = 2^40 (even 0-based columns) or -2^40
%      (odd columns), so each even/odd entry holds +2^80 and -2^80 and its value counts
%      the rows summed outside the lowest common subtree of rows a and b
%   C  inner products on twister vectors, n = 1..2,000: a'*b, b'*a, sum(a.*b), dot(a,b),
%      M(:,j)'*b, M(j,:)*b, M*b and b'*M (dots.bin), and FPRev rows of a'*b (dottrees.bin)
%   D  genuine lasso(X,y,'Alpha',alpha,'Lambda',lambda) on twister data at the V1362 scale
%      shapes, X = rand(L,w), y = rand(L,1) + sum of the first five columns (lasso.bin)
% Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output. V12 SEALED.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1365_SOURCE_DISCLOSED_GRAM_AND_DOT_ORDER_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'),'mkl_cbwr',getenv('MKL_CBWR'), ...
 'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(h,'%s\n',jsonencode(prov));fclose(h);
warning('off','backtrace');
failed=false;tStart=tic;

% ---------------- A. random Gram products ----------------
% gram.bin: 'CPMGM001'; per case u64 [case seed L w same], G (w*w words, column-major),
% then G2 = Z'*W only when same < w*w.
try
f=fopen(fullfile(outdir,'gram.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMGM001','char');
fc=fopen(fullfile(outdir,'gram_cases.csv'),'w');fprintf(fc,'case,seed,L,w,same\n');
c=0;
for L=[256 257 384 512 513 800 900 1000 1200 2000]
 for w=[65 120 180 252 337 360 400]
  seed=136500000+c;
  rng(seed,'twister');
  Z=rand(L,w)-0.5;
  G=Z'*Z;
  W=Z;W(1)=Z(1);
  G2=Z'*W;
  same=sum(typecast(G(:),'uint64')==typecast(G2(:),'uint64'));
  fwrite(f,uint64([c seed L w same]),'uint64');fwrite(f,typecast(G(:),'uint64'),'uint64');
  if same<w*w;fwrite(f,typecast(G2(:),'uint64'),'uint64');end
  fprintf(fc,'%d,%d,%d,%d,%d\n',c,seed,L,w,same);
  c=c+1;
 end
end
fclose(f);fclose(fc);
fprintf(logf,'A gram cases %d t=%.1f\n',c,toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. FPRev anchor rows of Z'*Z ----------------
% trees.bin: 'CPMGT001'; per anchor int32 [L w nE a nU], entries (nE x 2, 0-based i,j; first
% record of a shape only, nE = -nE otherwise omitted), U (nU x L int16, row-major), ids (nE
% int32, 0-based row of U). T(e,b) = L - value; T(e,a) = 0.
try
f=fopen(fullfile(outdir,'trees.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMGT001','char');
s=2^40;
for shp=[900 360;800 180;2000 252]'
 L=shp(1);w=shp(2);
 cs=unique([0:27, floor(w/2)-8:floor(w/2)+7, w-28:w-1]);
 [I,J]=meshgrid(cs,cs);I=I(:);J=J(:);
 keep=I~=J&mod(I,2)~=mod(J,2);I=I(keep);J=J(keep);
 idx=sub2ind([w w],I+1,J+1);nE=numel(idx);
 odd=logical(mod(0:w-1,2));
 an=unique([0 1 2 3 4 7 8 15 16 31 32 63 64 127 128 191 192 255 256 257 383 384 511 512 767 768 1023 1024 floor(L/2) L-2 L-1]);
 an=an(an<L);
 first=true;
 for a=an
  T=zeros(nE,L,'int16');
  for b=0:L-1
   if b==a;continue;end
   Z=ones(L,w);Z(a+1,:)=s;Z(b+1,:)=s;Z(b+1,odd)=-s;
   G=Z'*Z;
   T(:,b+1)=int16(L-round(G(idx)));
  end
  [U,~,ic]=unique(T,'rows');
  if first
   fwrite(f,int32([L w nE a size(U,1)]),'int32');fwrite(f,int32([I J]'),'int32');first=false;
  else
   fwrite(f,int32([L w -nE a size(U,1)]),'int32');
  end
  fwrite(f,U','int16');fwrite(f,int32(ic-1),'int32');
  fprintf(logf,'B tree L=%d w=%d a=%d uniq=%d t=%.1f\n',L,w,a,size(U,1),toc(tStart));
 end
end
fclose(f);
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- C. inner products ----------------
% dots.bin: 'CPMDT001'; per case u64 [case seed n hasM], then words: a'*b, b'*a, sum(a.*b),
% dot(a,b); if hasM: for j in jl (1, 2, floor(n/2)+1, n; duplicates kept) M(:,j)'*b and
% M(j,:)*b, then M*b (n words), then b'*M (n words). Inputs a = rand(n,1)-0.5,
% b = rand(n,1)-0.5, then M = rand(n,n)-0.5, in that order.
try
f=fopen(fullfile(outdir,'dots.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMDT001','char');
fc=fopen(fullfile(outdir,'dots_cases.csv'),'w');fprintf(fc,'case,seed,n,hasM\n');
ns=[1:96,100,127,128,129,177,180,187,200,250,252,255,256,257,300,323,337,357,360,370,399,400,511,512,513,800,900,1000,1200,2000];
c=0;
for n=ns
 seed=136510000+c;hasM=double(n<=1200);
 rng(seed,'twister');
 a=rand(n,1)-0.5;b=rand(n,1)-0.5;
 v=[a'*b;b'*a;sum(a.*b);dot(a,b)];
 if hasM
  M=rand(n,n)-0.5;
  jl=[1 min(2,n) floor(n/2)+1 n];
  e=zeros(8,1);
  for q=1:4;j=jl(q);e(2*q-1)=M(:,j)'*b;e(2*q)=M(j,:)*b;end
  v=[v;e;M*b;(b'*M)'];
 end
 fwrite(f,uint64([c seed n hasM]),'uint64');fwrite(f,typecast(v,'uint64'),'uint64');
 fprintf(fc,'%d,%d,%d,%d\n',c,seed,n,hasM);
 c=c+1;
end
fclose(f);fclose(fc);
fprintf(logf,'C dots %d t=%.1f\n',c,toc(tStart));
% dottrees.bin: 'CPMDR001'; per length int32 [n na], anchors (na), then T (na x n int16,
% row-major): T(a,b) = n - (a'*b) with a = ones except +2^80 at a and -2^80 at b; b = ones.
f=fopen(fullfile(outdir,'dottrees.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMDR001','char');
for n=[64 100 177 256 257 300 337 360 400 513 1000 2000]
 if n<=400;an=0:n-1;else;an=unique([0:9 15 16 31 32 63 64 127 128 255 256 257 511 512 767 768 1023 1024 floor(n/2) n-2 n-1]);an=an(an<n);end
 T=zeros(numel(an),n,'int16');
 o=ones(n,1);
 for ai=1:numel(an)
  aa=an(ai);
  for bb=0:n-1
   if bb==aa;continue;end
   x=o;x(aa+1)=2^80;x(bb+1)=-2^80;
   T(ai,bb+1)=int16(n-round(x'*o));
  end
 end
 fwrite(f,int32([n numel(an)]),'int32');fwrite(f,int32(an),'int32');fwrite(f,T','int16');
 fprintf(logf,'C dot tree n=%d anchors=%d t=%.1f\n',n,numel(an),toc(tStart));
end
fclose(f);
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- D. genuine lasso at the V1362 scale shapes ----------------
% lasso.bin: 'CPMLS001'; per case u64 [case seed L w nlam warned], alpha (1 word), lambda
% (nlam words, as passed), y (L words), then B (w*nlam), Intercept, MSE, DF, Lambda
% (nlam each), twice (the second fit repeats the first call). X = rand(L,w), then
% y = rand(L,1) + sum(X(:,1:5),2).
try
f=fopen(fullfile(outdir,'lasso.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMLS001','char');
fc=fopen(fullfile(outdir,'lasso_cases.csv'),'w');fprintf(fc,'case,seed,L,w,alpha,nlam,warn_id\n');
cfg={900,360,1e-9,0.1; 800,337,1e-9,0.1; 800,180,1e-9,[0.4 0.1 0.025]; 900,360,1e-6,0.1; ...
     1000,400,1e-9,0.1; 800,250,1e-9,[]; 900,120,1e-9,0.1; 800,65,1e-9,0.1; 800,64,1e-9,0.1; ...
     800,40,1e-9,0.1; 900,337,0.5,0.1; 800,300,1e-9,0.1};
for c=0:size(cfg,1)-1
 L=cfg{c+1,1};w=cfg{c+1,2};alpha=cfg{c+1,3};lam=cfg{c+1,4};
 seed=136520000+c;
 rng(seed,'twister');
 X=rand(L,w);y=rand(L,1)+sum(X(:,1:5),2);
 out=[];wid='';
 for rep=1:2
  lastwarn('');
  if isempty(lam)
   [B,FI]=lasso(X,y,'Alpha',alpha);
  else
   [B,FI]=lasso(X,y,'Alpha',alpha,'Lambda',lam);
  end
  [~,wid]=lastwarn;
  out=[out;B(:);FI.Intercept(:);FI.MSE(:);FI.DF(:);FI.Lambda(:)]; %#ok<AGROW>
 end
 nlam=numel(FI.Lambda);
 fwrite(f,uint64([c seed L w nlam ~isempty(wid)]),'uint64');
 fwrite(f,typecast([alpha;lam(:);y],'uint64'),'uint64');fwrite(f,typecast(out,'uint64'),'uint64');
 fprintf(fc,'%d,%d,%d,%d,%.17g,%d,%s\n',c,seed,L,w,alpha,nlam,wid);
 fprintf(logf,'D lasso L=%d w=%d alpha=%g nlam=%d warn=%s t=%.1f\n',L,w,alpha,nlam,wid,toc(tStart));
end
fclose(f);fclose(fc);
catch err
 failed=true;fprintf(logf,'SECTION D FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1365 section failed; see out/log.txt');
end
