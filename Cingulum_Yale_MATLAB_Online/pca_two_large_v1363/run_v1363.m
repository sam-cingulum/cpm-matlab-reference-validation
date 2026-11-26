function run_v1363()
% V1363 source-disclosed diagnostic (not evidence for any certificate): the economy QR and the
% one-component pca of n x 2 data, n = 9..2000, on genuine MATLAB R2026b Update 1. Inputs come
% from MATLAB's twister (rng(seed,'twister')), one statement per operation:
%   kind 0: X = rand(n,2) - 0.5
%   kind 1: U = rand(n,2) - 0.5; t = 0.6*U(:,1); X(:,2) = t + U(:,2); X(:,1) = U(:,1)
%   kind 2: kind 1, then X = round(X*4)/4
% For each case it writes mean(X) (2 words), R of [~,R] = qr(C,0) with C = X - mean(X)
% (r11, r12, r22), the pca loading (2 words) and X*loading (n words), twice.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
ns=[9:400,402:2:600,605:5:1000,1010:10:2000];
fh=[fopen(fullfile(outdir,'v1363.bin'),'w','ieee-le'),fopen(fullfile(outdir,'v1363_repeat.bin'),'w','ieee-le')];
fc=fopen(fullfile(outdir,'v1363_cases.csv'),'w');fprintf(fc,'case,seed,n,kind\n');
c=0;
for n=ns
 for kind=0:2
  seed=136300000+c;fprintf(fc,'%d,%d,%d,%d\n',c,seed,n,kind);
  for rep=1:2
   rng(seed,'twister');
   if kind==0
    X=rand(n,2)-0.5;
   else
    U=rand(n,2)-0.5;X=zeros(n,2);t=0.6*U(:,1);X(:,2)=t+U(:,2);X(:,1)=U(:,1);
    if kind==2;X=round(X*4)/4;end
   end
   mu=mean(X,1);C=X-mu;[~,R]=qr(C,0);
   loading=pca(X,'NumComponents',1);proj=X*loading;
   w=[mu(:);R(1,1);R(1,2);R(2,2);loading(:);proj(:)];
   fwrite(fh(rep),typecast(w,'uint64'),'uint64');
  end
  c=c+1;
 end
end
fclose('all');
prov=struct('classification','V1363_SOURCE_DISCLOSED_PCA_TWO_LARGE_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'),'mkl_cbwr',getenv('MKL_CBWR'), ...
 'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'cases',c);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end
