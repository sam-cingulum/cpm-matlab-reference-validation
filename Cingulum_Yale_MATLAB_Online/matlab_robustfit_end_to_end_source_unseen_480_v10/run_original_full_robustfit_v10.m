function run_original_full_robustfit_v10()
% V10 NEW original-source-unseen end-to-end robustfit oracle.
% Never execute until the entire compiled native Rust 480 full-field forecast,
% the offline exact scorer, and source-independent Rust code are git committed
% and pushed; the CI workflow enforces a supported AMD source CPU profile.
% The original MathWorks Statistics Toolbox robustfit is UNMODIFIED.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_RAW_XY_FULL_ROBUSTFIT_480_V10_SOURCE_UNSEEN'));
assert(numel(raw.cases)==480 && raw.seed==202611131906);
global CINGULUM_ORIGINAL_ROBUSTFIT_V10_CALLBACK;
records=struct('id',{},'n',{},'replicate',{},'scenario',{},'original_rep',{},...
  'pivot',{},'Q_col_major_hex',{},'R_coefficient_order_col_major_hex',{},...
  'Qy_coefficient_order_hex',{},'h_hex',{},'ols_s_hex',{},'std_y_hex',{},...
  'initial_beta_hex',{},'first_u_hex',{},'first_w_hex',{},'second_beta_hex',{},...
  'second_u_hex',{},'second_w_hex',{},'full_final_beta_hex',{},...
  'full_robust_s_hex',{},'full_mad_s_hex',{},'full_s_hex',{},...
  'full_w_hex',{},'full_expected_original_callback_count',{},...
  'full_t_hex',{},'full_se_hex',{},'full_p_hex',{},'full_dfe_hex',{},...
  'callback_does_not_perturb_original',{});
for original_rep=1:2
 for i=1:480
  c=raw.cases(i);
  x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
  x=x(:);y=y(:);n=numel(x);
  X=[ones(n,1),x];
  assert(n==double(c.n) && numel(y)==n && n>=9 && n<=25);
  assert(isequal(cellstr(num2hex(x)),cellstr(char(c.x_hex))));
  assert(isequal(cellstr(num2hex(y)),cellstr(char(c.y_hex))));
  [Q,R,pivot]=qr(X,'econ','vector');
  [b,st]=robustfit(x,y);
  CINGULUM_ORIGINAL_ROBUSTFIT_V10_CALLBACK={};
  [bc,sc]=robustfit(x,y,@capture_original_bisquare_v10,4.685);
  cb=CINGULUM_ORIGINAL_ROBUSTFIT_V10_CALLBACK;
  assert(numel(cb)>=4 && numel(cb)<=53);
  assert(isequal(num2hex(b(:)),num2hex(bc(:))));
  for field={'robust_s','mad_s','s','w','h','R','Qy','ols_s','t','se','p','dfe'}
    name=field{1};
    assert(isequal(num2hex(st.(name)),num2hex(sc.(name))),...
      sprintf('callback changed original robustfit field %s at case %d',name,i));
  end
  weightedX=X.*sqrt(cb{1}.w);
  weightedY=y.*sqrt(cb{1}.w);
  b2=weightedX\weightedY;
  row=struct();
  row.id=c.id;row.n=n;row.replicate=c.replicate;row.scenario=c.scenario;
  row.original_rep=original_rep;row.pivot=pivot;
  row.Q_col_major_hex=cellstr(num2hex(Q(:)));
  row.R_coefficient_order_col_major_hex=cellstr(num2hex(st.R(:)));
  row.Qy_coefficient_order_hex=cellstr(num2hex(st.Qy(:)));
  row.h_hex=cellstr(num2hex(st.h(:)));
  row.ols_s_hex=num2hex(st.ols_s);
  row.std_y_hex=num2hex(std(y));
  row.initial_beta_hex=cellstr(num2hex(X\y));
  row.first_u_hex=cellstr(num2hex(cb{1}.u(:)));
  row.first_w_hex=cellstr(num2hex(cb{1}.w(:)));
  row.second_beta_hex=cellstr(num2hex(b2(:)));
  row.second_u_hex=cellstr(num2hex(cb{2}.u(:)));
  row.second_w_hex=cellstr(num2hex(cb{2}.w(:)));
  row.full_final_beta_hex=cellstr(num2hex(b(:)));
  row.full_robust_s_hex=num2hex(st.robust_s);
  row.full_mad_s_hex=num2hex(st.mad_s);
  row.full_s_hex=num2hex(st.s);
  row.full_w_hex=cellstr(num2hex(st.w(:)));
  row.full_expected_original_callback_count=numel(cb);
  row.full_t_hex=cellstr(num2hex(st.t(:)));
  row.full_se_hex=cellstr(num2hex(st.se(:)));
  row.full_p_hex=cellstr(num2hex(st.p(:)));
  row.full_dfe_hex=num2hex(st.dfe);
  row.callback_does_not_perturb_original=true;
  records(end+1)=row; %#ok<AGROW>
  CINGULUM_ORIGINAL_ROBUSTFIT_V10_CALLBACK={};
  if mod(i,80)==0
    fprintf('GENUINE ORIGINAL MATLAB V10 FULL ROBUSTFIT rep=%d cases=%d/480\n',original_rep,i);
  end
 end
end
report=struct('status','ORIGINAL_MATHWORKS_R2026B_FULL_ROBUSTFIT_480_V10_SOURCE_UNSEEN',...
 'release',version('-release'),'matlab_version',version,'computer',computer,...
 'mkl_cbwr',getenv('MKL_CBWR'),'max_num_comp_threads',maxNumCompThreads,...
 'case_count',480,'original_repetitions',2,...
 'new_input_sha256','aee017a203f286c70333eea04d2229fdd380d86c0d8c98e0f748a3587b09b41a',...
 'pre_oracle_native_Rust_frozen_forecast_sha256','08d747315c5d2babbe265628f14ad08ce3137e5ad99e30987d55ea498af44a25',...
 'original_unmodified',true,'callback_noninterference_asserted',true,...
 'records',records);
outfile=getenv('V10_ORIGINAL_FULL_OUTPUT');assert(~isempty(outfile));
fd=fopen(fullfile(root,outfile),'w');assert(fd>0);clean=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
end
function w=capture_original_bisquare_v10(u)
global CINGULUM_ORIGINAL_ROBUSTFIT_V10_CALLBACK;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_ORIGINAL_ROBUSTFIT_V10_CALLBACK{end+1}=struct('u',double(u(:)),'w',double(w(:)));
end
