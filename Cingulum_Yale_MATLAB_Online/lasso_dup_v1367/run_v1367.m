function run_v1367()
% V1367 source-disclosed diagnostic (not evidence for any certificate): genuine
% lasso(X,y,'Alpha',alpha,'Lambda',lambda) when the Lambda vector repeats values or holds 0,
% as Yale's ridgeCPM_PCA passes a user grid straight to lasso. Same layout as V1365 section D
% (lasso.bin 'CPMLS001'): per case u64 [case seed L w nlam warned], alpha, lambda (as passed),
% y, then B, Intercept, MSE, DF, Lambda, twice. X = rand(L,w), y = rand(L,1) + sum(X(:,1:5),2).
% Each call's error (if any) goes to errors.tsv. Synthetic inputs only. V12 SEALED.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
prov=struct('classification','V1367_SOURCE_DISCLOSED_LASSO_DUPLICATE_LAMBDA_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'mkl_cbwr',getenv('MKL_CBWR'), ...
 'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(h,'%s\n',jsonencode(prov));fclose(h);
warning('off','backtrace');
f=fopen(fullfile(outdir,'lasso.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMLS001','char');
fc=fopen(fullfile(outdir,'lasso_cases.csv'),'w');fprintf(fc,'case,seed,L,w,alpha,nlam,warn_id\n');
fe=fopen(fullfile(outdir,'errors.tsv'),'w');
cfg={32,20,1e-6,[0.05 0.05 0.5]; 40,25,1e-9,[0.4 0.4 0.1 0.1]; 40,30,1e-9,[0.2 0.05 0.05 1]; ...
     36,15,1e-6,[0.1 0.1 0.1]; 48,40,0.5,[0.05 0.05 0.5]; 200,60,1e-9,[0.3 0.3 0.03]; ...
     800,180,1e-9,[0.1 0.1 0.025 0.4]; 60,20,1e-9,[0 0.1]; 60,20,1e-9,[0.1 0]; 60,20,1e-9,0; ...
     60,20,1,[0 0 0.2]; 900,120,1e-6,[0.4 0.1 0.1 0.025 0.025]};
for c=0:size(cfg,1)-1
 L=cfg{c+1,1};w=cfg{c+1,2};alpha=cfg{c+1,3};lam=cfg{c+1,4};
 seed=136670000+c;
 rng(seed,'twister');
 X=rand(L,w);y=rand(L,1)+sum(X(:,1:5),2);
 out=[];wid='';ok=true;
 for rep=1:2
  lastwarn('');
  try
   [B,FI]=lasso(X,y,'Alpha',alpha,'Lambda',lam);
  catch e
   fprintf(fe,'%d\t%d\t%s\t%s\n',c,rep,e.identifier,regexprep(e.message,'[\t\r\n]',' '));ok=false;break;
  end
  [~,wid]=lastwarn;
  out=[out;B(:);FI.Intercept(:);FI.MSE(:);FI.DF(:);FI.Lambda(:)]; %#ok<AGROW>
 end
 if ~ok;fprintf(fc,'%d,%d,%d,%d,%.17g,error,-\n',c,seed,L,w,alpha);continue;end
 nlam=numel(FI.Lambda);
 fwrite(f,uint64([c seed L w nlam ~isempty(wid)]),'uint64');
 fwrite(f,typecast([alpha;lam(:);y],'uint64'),'uint64');fwrite(f,typecast(out,'uint64'),'uint64');
 fprintf(fc,'%d,%d,%d,%d,%.17g,%d,%s\n',c,seed,L,w,alpha,nlam,wid);
end
fclose('all');
end
