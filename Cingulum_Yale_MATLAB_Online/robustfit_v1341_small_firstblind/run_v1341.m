function run_v1341()
% V1341 original-only firstblind robustfit on small fits (rows = coefficients + 1..5).
% Reads the frozen synthetic input container only (CPMRFI01: magic, uint64 case count, then
% per case uint64 rows, predictors and the column-major doubles of X and of y) and writes
% what genuine, unchanged MATLAB robustfit(X,y) returns (b and all 17 stats fields), twice.
% No MEX, no twin, no Rust forecast, no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
fields={'ols_s','robust_s','mad_s','s','resid','rstud','se','covb','coeffcorr','t','p','w','Qy','R','dfe','h','Rtol'};
% The rank comes from stats.dfe. The iteration-limit flag comes from lastwarn: robustfit
% issues that warning after its rank warning, so it is the last one when it occurs. Any
% other warning id is recorded; the flag is then asked for again with the limit warning
% turned into an error (limit_by_error), and is -1 (unknown, rejected by the audit) if
% that does not settle it. The outputs always come from the plain calls.
warning('off','backtrace');
notes={};
names={'hidden.bin','hidden_repeat.bin'};
metas=cell(1,2);
words=0;
for rep=1:2
 f=fopen(fullfile(root,'input.bin'),'r','ieee-le');assert(f>0);
 magic=fread(f,8,'uint8=>char')';assert(strcmp(magic,'CPMRFI01'));
 nc=fread(f,1,'uint64');
 o=fopen(fullfile(outdir,names{rep}),'w','ieee-le');assert(o>0);
 meta=zeros(nc,5);
 words=0;
 for i=1:nc
  d=fread(f,2,'uint64');n=d(1);k=d(2);p=k+1;
  X=reshape(fread(f,n*k,'double'),n,k);
  y=fread(f,n,'double');
  assert(isequal(size(X),[n k])&&isequal(size(y),[n 1]));
  lastwarn('');
  [b,s]=robustfit(X,y);
  [wm,wid]=lastwarn;
  limit=0;
  if strcmp(wid,'stats:statrobustfit:IterationLimit')
   limit=1;
  elseif ~isempty(wm)&&~strcmp(wid,'stats:robustfit:RankDeficient')
   limit=limit_by_error(X,y);
   if rep==1;notes{end+1}=struct('case',i-1,'id',wid,'msg',wm,'limit',limit);end %#ok<AGROW>
  end
  assert(isequal(size(b),[p 1]));
  assert(isequal(fieldnames(s)',fields));
  fwrite(o,b(:),'double');
  words=words+p;
  for q=1:numel(fields)
   v=double(s.(fields{q}));
   fwrite(o,v(:),'double');
   words=words+numel(v);
  end
  meta(i,:)=[i-1 n k n-s.dfe limit];
 end
 assert(isempty(fread(f,1,'uint8')));
 fclose(f);fclose(o);
 metas{rep}=meta;
end
assert(isequal(metas{1},metas{2}));
writematrix(metas{1},fullfile(outdir,'hidden_meta.csv'));
prov=struct('classification','V1341_ORIGINAL_ONLY_ROBUSTFIT_SMALL_FIRSTBLIND','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false,'cases',nc,'words',words, ...
 'rank_deficient_cases',sum(metas{1}(:,4)<metas{1}(:,3)+1), ...
 'iteration_limit_cases',sum(metas{1}(:,5)));
prov.other_warnings=notes;
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(prov));
fclose(f);
end

function limit=limit_by_error(X,y)
% 1 when robustfit raises its iteration-limit warning, 0 when it does not, -1 when unknown.
limit=-1;
st=warning;
restore=onCleanup(@()warning(st));
try
 warning('error','stats:statrobustfit:IterationLimit');
 robustfit(X,y);
 limit=0;
catch e
 if strcmp(e.identifier,'stats:statrobustfit:IterationLimit');limit=1;end
end
end
