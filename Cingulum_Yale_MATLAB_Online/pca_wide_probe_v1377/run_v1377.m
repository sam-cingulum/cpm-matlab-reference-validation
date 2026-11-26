function run_v1377()
% V1377 SOURCE-DISCLOSED DIAGNOSTIC (not evidence for any certificate). MATLAB's own
% pca(X,'NumComponents',1) of n x p twister data with n <= p (p = 3..6, n = 2..p; pca_cases.csv,
% seeds 137,700,000 + case, V1376's data rule), with the factorizations that could produce it:
% [U,S,V] = svd(C,'econ') and [U2,S2,V2] = svd(C.','econ') of the centred data C, qr(C.',0) and
% qr(C,0), and whether pca's loading equals V(:,1) or U2(:,1) after pca's sign rule. Twice.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'pca','svd','qr','rng','rand'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
lines=strsplit(strtrim(fileread(fullfile(root,'pca_cases.csv'))),newline);
assert(strcmp(lines{1},'case,seed,n,p,kind'));
fh=[fopen(fullfile(outdir,'wide.bin'),'w','ieee-le'),fopen(fullfile(outdir,'wide_repeat.bin'),'w','ieee-le')];
fs=[fopen(fullfile(outdir,'wide_status.tsv'),'w'),fopen(fullfile(outdir,'wide_status_repeat.tsv'),'w')];
assert(all([fh fs]>0));
for li=2:numel(lines)
 v=str2double(strsplit(strtrim(lines{li}),','));assert(numel(v)==5&&v(1)==li-2);
 c=v(1);seed=v(2);n=v(3);p=v(4);kind=v(5);
 for rep=1:2
  X=pcadata(seed,n,p,kind);
  try
   mu=mean(X,1);C=X-mu;
   [U,S,V]=svd(C,'econ');[U2,S2,V2]=svd(C.','econ');
   [~,Rt]=qr(C.',0);[~,R]=qr(C,0);
   coef=pca(X,'NumComponents',1);
   w=[n;p;mu(:);U(:);diag(S);V(:);U2(:);diag(S2);V2(:);Rt(:);R(:);numel(coef);coef(:)];
   fwrite(fh(rep),typecast(w,'uint64'),'uint64');
   eqV=isequal(coef,V(:,1))||isequal(coef,-V(:,1));eqU2=isequal(coef,U2(:,1))||isequal(coef,-U2(:,1));
   fprintf(fs(rep),'%d\treturned\t%d\t%d\t%d\n',c,numel(w),eqV,eqU2);
  catch e
   fprintf(fs(rep),'%d\terror\t%s\t%s\n',c,dash(e.identifier),dash(e.message));
  end
 end
end
fclose('all');
prov=struct('classification','V1377_SOURCE_DISCLOSED_PCA_WIDE_PROBE_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false,'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function s=dash(s)
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end


function X=pcadata(seed,n,p,kind)
% One statement per operation, so no two operations can be fused.
rng(seed,'twister');
X=rand(n,p)-0.5;
switch kind
 case 0
 case 1;X=round(X*4)/4;
 case 2;X(:,mod(seed,p)+1)=0;
 case 3;t=0.5*X(:,1);X(:,2)=t;X(:,p)=X(:,1);
 case 4
  m=min(3,n);X(1:m,:)=0;
  if n>=2;X(2,:)=-X(2,:);end
  if n>=3;X(3,2:2:p)=-X(3,2:2:p);end
 case 5
  for j=1:p;t=10^(j-3);X(:,j)=t*X(:,j);end
 otherwise;error('bad kind %d',kind);
end
end
