function run_original_v208()
% ORIGINAL MathWorks R2026b Update1 special-function boundary oracle.
% It must not run before pure Rust exp/erfc predictions and strict scorer
% have been committed; genuine gamma/beta/tcdf are ORIGINAL-ONLY forensic
% observations, not fabricated native Rust forecasts.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,'V208_ORIGINAL_MATLAB_R2026B_GENERAL_SPECIAL_FIRST_BLIND_INPUT'));
assert(double(raw.seed)==202611220208);
xs=hex2num(char(raw.exp_x_hex));xs=xs(:);
es=hex2num(char(raw.erfc_x_hex));es=es(:);
assert(numel(xs)==365 && numel(es)==231);
assert(isequal(cellstr(num2hex(xs)),cellstr(char(raw.exp_x_hex))));
assert(isequal(cellstr(num2hex(es)),cellstr(char(raw.erfc_x_hex))));
assert(numel(raw.gamma_cases)==60 && numel(raw.beta_cases)==55 && numel(raw.tcdf_cases)==91);
rows=struct('rep',{},'exp_hex',{},'erfc_hex',{},'erfcx_hex',{}, ...
 'gamma_lower_hex',{},'gamma_upper_hex',{},'beta_lower_hex',{}, ...
 'beta_upper_hex',{},'tcdf_lower_hex',{},'tcdf_twosided_hex',{});
for rep=1:2
 gamma_lower=zeros(numel(raw.gamma_cases),1);
 gamma_upper=zeros(numel(raw.gamma_cases),1);
 for k=1:numel(raw.gamma_cases)
  c=raw.gamma_cases(k);
  a=hex2num(c.a_hex);x=hex2num(c.x_hex);
  gamma_lower(k)=gammainc(x,a,'lower');
  gamma_upper(k)=gammainc(x,a,'upper');
 end
 beta_lower=zeros(numel(raw.beta_cases),1);
 beta_upper=zeros(numel(raw.beta_cases),1);
 for k=1:numel(raw.beta_cases)
  c=raw.beta_cases(k);
  a=hex2num(c.a_hex);b=hex2num(c.b_hex);x=hex2num(c.x_hex);
  beta_lower(k)=betainc(x,a,b);
  beta_upper(k)=betainc(x,a,b,'upper');
 end
 tcdf_lower=zeros(numel(raw.tcdf_cases),1);
 tcdf_twosided=zeros(numel(raw.tcdf_cases),1);
 for k=1:numel(raw.tcdf_cases)
  c=raw.tcdf_cases(k);
  t=hex2num(c.t_hex);df=hex2num(c.df_hex);
  tcdf_lower(k)=tcdf(t,df);
  tcdf_twosided(k)=2*tcdf(-abs(t),df);
 end
 row=struct();
 row.rep=rep;
 row.exp_hex=cellstr(num2hex(exp(xs)));
 row.erfc_hex=cellstr(num2hex(erfc(es)));
 row.erfcx_hex=cellstr(num2hex(erfcx(es)));
 row.gamma_lower_hex=cellstr(num2hex(gamma_lower));
 row.gamma_upper_hex=cellstr(num2hex(gamma_upper));
 row.beta_lower_hex=cellstr(num2hex(beta_lower));
 row.beta_upper_hex=cellstr(num2hex(beta_upper));
 row.tcdf_lower_hex=cellstr(num2hex(tcdf_lower));
 row.tcdf_twosided_hex=cellstr(num2hex(tcdf_twosided));
 rows(end+1)=row; %#ok<AGROW>
end
report=struct('classification','V208_GENUINE_ORIGINAL_MATHWORKS_R2026B_SPECIAL_FUNCTION_GRID', ...
 'release',version,'computer',computer,'mkl_cbwr',getenv('MKL_CBWR'), ...
 'max_num_comp_threads',maxNumCompThreads, ...
 'input_sha256','9f79996833bdef6fead22f1a2880ee0430966ba8aa0a419d31ea1e7ab0e3928d', ...
 'run',getenv('GITHUB_RUN_ID'),'repetitions',2,'original_functions_unchanged',true, ...
 'hist_disclosed_exp_one_control',true,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(report));
end
