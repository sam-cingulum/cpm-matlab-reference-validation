function run_v1372()
% V1372 SOURCE-DISCLOSED DIAGNOSTIC (not evidence for any certificate): cov(X) of n x w twister
% data, the covariance Yale's Hotelling code forms (cov of each group's features), on the
% shapes no Hotelling firstblind reached: groups of 2 to 40 rows (including exactly 8 and 9,
% where MATLAB's X'*X is a plain serial sum below 10 columns, V1368) and the K-block edges
% 250..262, 380..390 and 508..516 rows, widths 1 to 12. One statement per operation:
%   rng(seed,'twister'); X = rand(n,w) - 0.5;  C = cov(X);  Xc = X - mean(X,1);  G = Xc'*Xc;
% For each case it writes mean(X,1) (w words), C (w*w, column-major) and G (w*w), twice.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
assert(startsWith(which('cov'),matlabroot));
root=fileparts(mfilename('fullpath'));outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
ns=[2:40,250:262,380:390,508:516];
fh=[fopen(fullfile(outdir,'v1372.bin'),'w','ieee-le'),fopen(fullfile(outdir,'v1372_repeat.bin'),'w','ieee-le')];
fc=fopen(fullfile(outdir,'v1372_cases.csv'),'w');fprintf(fc,'case,seed,n,w\n');
c=0;
for n=ns
 for w=1:12
  seed=137200000+c;fprintf(fc,'%d,%d,%d,%d\n',c,seed,n,w);
  for rep=1:2
   rng(seed,'twister');X=rand(n,w)-0.5;
   C=cov(X);mu=mean(X,1);Xc=X-mu;G=Xc'*Xc;
   v=[mu(:);C(:);G(:)];
   fwrite(fh(rep),typecast(v,'uint64'),'uint64');
  end
  c=c+1;
 end
end
fclose('all');
prov=struct('classification','V1372_SOURCE_DISCLOSED_COV_SMALL_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'),'mkl_cbwr',getenv('MKL_CBWR'), ...
 'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'cases',c);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end
