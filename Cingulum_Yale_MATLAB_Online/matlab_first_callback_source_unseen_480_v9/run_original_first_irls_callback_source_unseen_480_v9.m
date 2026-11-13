function run_original_first_irls_callback_source_unseen_480_v9()
% PREORACLE original MathWorks R2026b first IRLS callback u/w source-unseen.
% The ENTIRE independent compiled Rust raw-x/y prediction was frozen and
% pushed BEFORE the original executes: Cingulum CPM private commit 189053c.
% Original robustfit is unmodified. Callback is an independently authored
% bisquare implementation used solely to observe the original callback u.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
p=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(p,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_RAW_XY_FIRST_BISQUARE_CALLBACK_480_V9'));
assert(numel(raw.cases)==480);
global CINGULUM_IRLS_V9_CALLBACKS;
records=struct('id',{},'n',{},'iteration',{},'pivot',{},...
 'Q_hex',{},'source_R_hex',{},'source_h_hex',{},'source_Qy_hex',{},...
 'source_ols_s_hex',{},'source_std_y_hex',{},'source_initial_beta_backslash_hex',{},...
 'source_first_callback_u_hex',{},'source_first_callback_w_hex',{},...
 'source_callback_count',{},'source_final_beta_hex',{},...
 'source_final_robust_s_hex',{},'source_first_callback_noninterference',{});
for iteration=1:2
 for k=1:numel(raw.cases)
  c=raw.cases(k);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
  x=x(:);y=y(:);n=numel(x);X=[ones(n,1),x];
  assert(n==double(c.n) && numel(y)==n && n>=9 && n<=128);
  assert(isequal(cellstr(num2hex(x)),cellstr(char(c.x_hex))));
  assert(isequal(cellstr(num2hex(y)),cellstr(char(c.y_hex))));
  [Q,R,pivot]=qr(X,'econ','vector');
  [b,st]=robustfit(x,y);
  CINGULUM_IRLS_V9_CALLBACKS={};
  [b_cb,st_cb]=robustfit(x,y,@capture_bisquare_u_w_v9,4.685);
  callbacks=CINGULUM_IRLS_V9_CALLBACKS;
  assert(numel(callbacks)>=3 && numel(callbacks)<100);
  assert(isequal(num2hex(b),num2hex(b_cb)));
  assert(isequal(num2hex(st.robust_s),num2hex(st_cb.robust_s)));
  assert(isequal(num2hex(st.mad_s),num2hex(st_cb.mad_s)));
  assert(isequal(num2hex(st.s),num2hex(st_cb.s)));
  assert(isequal(num2hex(st.w),num2hex(st_cb.w)));
  assert(all(isfinite(callbacks{1}.u)) && all(isfinite(callbacks{1}.w)));
  assert(numel(callbacks{1}.u)==n && numel(callbacks{1}.w)==n);
  assert(all(callbacks{1}.w>=0 & callbacks{1}.w<=1));
  row=struct();row.id=c.id;row.n=n;row.iteration=iteration;row.pivot=pivot;
  row.Q_hex=cellstr(num2hex(Q(:)));
  row.source_R_hex=cellstr(num2hex(st.R(:)));
  row.source_h_hex=cellstr(num2hex(st.h(:)));
  row.source_Qy_hex=cellstr(num2hex(st.Qy(:)));
  row.source_ols_s_hex=num2hex(st.ols_s);
  row.source_std_y_hex=num2hex(std(y));
  row.source_initial_beta_backslash_hex=cellstr(num2hex(X\y));
  row.source_first_callback_u_hex=cellstr(num2hex(callbacks{1}.u(:)));
  row.source_first_callback_w_hex=cellstr(num2hex(callbacks{1}.w(:)));
  row.source_callback_count=numel(callbacks);
  row.source_final_beta_hex=cellstr(num2hex(b(:)));
  row.source_final_robust_s_hex=num2hex(st.robust_s);
  row.source_first_callback_noninterference=true;
  records(end+1)=row; %#ok<AGROW>
  CINGULUM_IRLS_V9_CALLBACKS={};
  if mod(k,80)==0
   fprintf('ORIGINAL_MATHWORKS_V9_FIRST_CALLBACK iteration=%d cases=%d/480\n',iteration,k);
  end
 end
end
report=struct('status','ORIGINAL_MATHWORKS_R2026B_SOURCE_UNSEEN_INITIAL_IRLS_CALLBACK_V9',...
 'release',version('-release'),'matlab_version',version,'computer',computer,...
 'max_num_comp_threads',maxNumCompThreads,'mkl_cbwr',getenv('MKL_CBWR'),...
 'input_sha256','d85eb82d20f1293436c8d510026f63bb89f79be28346f67b839df11f46c7093d',...
 'sealed_private_commit','189053c7c76bf0d6643dfec5cef0c85192d55dfb',...
 'sealed_frozen_forecast_sha256','e6d49b317945dfe94a98e764361cb2617fc1dbb3aeecaf80cb4eca3c3b5784b5',...
 'original_unmodified',true,'callback_noninterference_asserted',true,...
 'case_count',480,'iterations',2,'records',records);
output=getenv('FIRST_IRLS_V9_OUTPUT');assert(~isempty(output));
f=fopen(fullfile(p,output),'w');assert(f>0);clean=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(report));
end
function w=capture_bisquare_u_w_v9(u)
% Published bisquare arithmetic, not extracted from proprietary code.
global CINGULUM_IRLS_V9_CALLBACKS;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_IRLS_V9_CALLBACKS{end+1}=struct('u',double(u(:)),'w',double(w(:)));
end
