function run_original_v203()
% Cingulum V203 first-blind original MathWorks MATLAB R2026b robustfit.
% Do not execute until original input, pure-Rust numeric forecast, exact
% scorer, CPU-locked workflow and their SHA manifests are committed/pushed.
% ZERO original MATLAB numeric values are supplied to the Rust predictor.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_RAW_XY_FULL_ROBUSTFIT_480_V203_SOURCE_UNSEEN'));
assert(raw.seed==202611220203 && numel(raw.cases)==480);
expected={'ols_s';'robust_s';'mad_s';'s';'resid';'rstud';'se';'covb'; ...
  'coeffcorr';'t';'p';'w';'Qy';'R';'dfe';'h';'Rtol'};
rows=struct('id',{},'n',{},'original_rep',{},'original_fieldnames',{}, ...
 'beta_hex',{},'ols_s_hex',{},'robust_s_hex',{},'mad_s_hex',{}, ...
 's_hex',{},'resid_hex',{},'rstud_hex',{},'se_hex',{}, ...
 'covb_hex',{},'coeffcorr_hex',{},'t_hex',{},'p_hex',{}, ...
 'w_hex',{},'Qy_hex',{},'R_hex',{},'dfe_hex',{},'h_hex',{},'Rtol_hex',{});
for rep=1:2
 for k=1:480
  c=raw.cases(k);
  x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
  x=x(:);y=y(:);
  assert(numel(x)==double(c.n) && numel(y)==double(c.n));
  assert(c.n>=9 && c.n<=25);
  assert(isequal(cellstr(num2hex(x)),cellstr(char(c.x_hex))));
  assert(isequal(cellstr(num2hex(y)),cellstr(char(c.y_hex))));
  [b,st]=robustfit(x,y); % UNCHANGED MathWorks Statistics Toolbox
  fields=fieldnames(st);
  assert(isequal(fields,expected),'unregistered original stats structure fields');
  row=struct();
  row.id=c.id;row.n=double(c.n);row.original_rep=rep;
  row.original_fieldnames=fields;
  row.beta_hex=cellstr(num2hex(b(:)));
  row.ols_s_hex=cellstr(num2hex(st.ols_s(:)));
  row.robust_s_hex=cellstr(num2hex(st.robust_s(:)));
  row.mad_s_hex=cellstr(num2hex(st.mad_s(:)));
  row.s_hex=cellstr(num2hex(st.s(:)));
  row.resid_hex=cellstr(num2hex(st.resid(:)));
  row.rstud_hex=cellstr(num2hex(st.rstud(:)));
  row.se_hex=cellstr(num2hex(st.se(:)));
  row.covb_hex=cellstr(num2hex(st.covb(:)));
  row.coeffcorr_hex=cellstr(num2hex(st.coeffcorr(:)));
  row.t_hex=cellstr(num2hex(st.t(:)));
  row.p_hex=cellstr(num2hex(st.p(:)));
  row.w_hex=cellstr(num2hex(st.w(:)));
  row.Qy_hex=cellstr(num2hex(st.Qy(:)));
  row.R_hex=cellstr(num2hex(st.R(:)));
  row.dfe_hex=cellstr(num2hex(st.dfe(:)));
  row.h_hex=cellstr(num2hex(st.h(:)));
  row.Rtol_hex=cellstr(num2hex(st.Rtol(:)));
  rows(end+1)=row; %#ok<AGROW>
 end
 fprintf('GENUINE ORIGINAL V203 complete original repetition %d/2 (480 fits)\n',rep);
end
report=struct('status','ORIGINAL_MATHWORKS_V203_FIRST_BLIND_17_STATS', ...
 'matlab_version',version,'release',version('-release'), ...
 'computer',computer,'mkl_cbwr',getenv('MKL_CBWR'), ...
 'max_num_comp_threads',maxNumCompThreads, ...
 'original_robustfit_unchanged',true,'case_count',480,'original_repetitions',2, ...
 'raw_input_sha256','0b12e8fff4603b2cf3fec14c34dbe7ed517736804e877aacba4b08596433a375', ...
 'preoracle_Rust_gzip_forecast_sha256','845cdfbff063433d2a81473c12d481c29cf9dcdb0c70aefad8206b5dd5372530', ...
 'records',rows);
fd=fopen(fullfile(root,'original_v203.json'),'w');
assert(fd>0);
cleanup=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
end
