function run_original_v211()
% V211 genuine unchanged MATLAB raw multi-column robustfit original-only.
% Execute only after independent Rust OLS predictor and first scorer frozen.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND'));
assert(raw.seed==202611220211 && numel(raw.cases)==48);
fields={'ols_s';'robust_s';'mad_s';'s';'resid';'rstud';'se';'covb'; ...
        'coeffcorr';'t';'p';'w';'Qy';'R';'dfe';'h';'Rtol'};
rows=struct('id',{},'n',{},'p',{},'rep',{}, ...
 'ols_beta_hex',{},'robust_beta_hex',{}, ...
 'fieldnames',{},'full_robust_stats_hex',{});
for rep=1:2
 for i=1:48
  c=raw.cases(i);
  n=double(c.n);p=double(c.p);
  assert(ismember(n,[33 49 73]) && ismember(p,[2 3 4 5]));
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,p);
  y=hex2num(char(c.y_hex));y=y(:);
  assert(isequal(cellstr(num2hex(X(:))),cellstr(char(c.x_colmajor_hex))));
  assert(isequal(cellstr(num2hex(y)),cellstr(char(c.y_hex))));
  A=[ones(n,1),X];
  ols=A\y;
  [b,stats]=robustfit(X,y);
  fn=fieldnames(stats);
  assert(isequal(fn,fields),'Original returned unexpected robustfit statistics fields');
  assert(numel(b)==p+1 && numel(ols)==p+1);
  st=struct();
  for j=1:numel(fields)
   k=fields{j};
   v=stats.(k);st.(k)=cellstr(num2hex(v(:)));
  end
  row=struct();
  row.id=c.id;row.n=n;row.p=p;row.rep=rep;
  row.ols_beta_hex=cellstr(num2hex(ols(:)));
  row.robust_beta_hex=cellstr(num2hex(b(:)));
  row.fieldnames=fn;
  row.full_robust_stats_hex=st;
  rows(end+1)=row; %#ok<AGROW>
 end
end
assert(numel(rows)==96);
report=struct('classification','V211_GENUINE_MATHWORKS_R2026B_UPDATE1_MULTIPREDICTOR_ROBUSTFIT_ORIGINAL', ...
 'release',version,'computer',computer,'mkl_cbwr',getenv('MKL_CBWR'), ...
 'max_num_comp_threads',maxNumCompThreads,'original_robustfit_unchanged',true, ...
 'original_run',getenv('GITHUB_RUN_ID'), ...
 'input_sha256','5836d8f460b64c889feda69ee69dc4792a5ff85bf120600f346171150eb2a559', ...
 'case_count',48,'original_repetitions',2,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
closefile=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(report));
end
