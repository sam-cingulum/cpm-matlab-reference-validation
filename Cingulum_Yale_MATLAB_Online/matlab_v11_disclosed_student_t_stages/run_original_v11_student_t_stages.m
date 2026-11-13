function run_original_v11_student_t_stages()
% SOURCE-DISCLOSED diagnostics only. Reuses V11 previously revealed raw x/y.
% Original MathWorks robustfit, tcdf, betainc, betaln and gammaln UNMODIFIED.
% Never reinterpret this output as a V12 new source-unseen result.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
src=fullfile(root,'..','matlab_robustfit_end_to_end_source_unseen_480_v11','input.json');
raw=jsondecode(fileread(src));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_RAW_XY_FULL_ROBUSTFIT_480_V11_SOURCE_UNSEEN'));
assert(raw.seed==202611131963 && numel(raw.cases)==480);
records=struct('id',{},'rep',{},'n',{},'coef_index',{},'source_t_hex',{},...
 'source_p_hex',{},'source_dfe_hex',{},'t_abs_hex',{},...
 't_squared_hex',{},'dfe_plus_t_squared_hex',{},...
 'lower_x_hex',{},'upper_u_hex',{},'df_half_hex',{},...
 'betaln_hex',{},'gammaln_df_half_hex',{},...
 'gammaln_half_hex',{},'gammaln_df_half_plus_half_hex',{},...
 'log_lower_x_hex',{},'log_upper_u_hex',{},...
 'log1p_negative_lower_x_hex',{},'log1p_negative_upper_u_hex',{},...
 'source_betainc_lower_hex',{},'source_betainc_upper_hex',{},...
 'source_tcdf_negative_hex',{});
for rep=1:2
 for i=1:480
  c=raw.cases(i);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
  assert(numel(x)==c.n && numel(y)==c.n);
  [~,st]=robustfit(x(:),y(:)); % unchanged genuine MATLAB function
  dfe=st.dfe;
  for j=1:2
   t=abs(st.t(j));t2=t*t;den=dfe+t2;
   a=dfe/2;lower_x=dfe/den;upper_u=t2/den;
   row=struct();row.id=c.id;row.rep=rep;row.n=double(c.n);
   row.coef_index=j;row.source_t_hex=num2hex(st.t(j));
   row.source_p_hex=num2hex(st.p(j));
   row.source_dfe_hex=num2hex(dfe);row.t_abs_hex=num2hex(t);
   row.t_squared_hex=num2hex(t2);row.dfe_plus_t_squared_hex=num2hex(den);
   row.lower_x_hex=num2hex(lower_x);row.upper_u_hex=num2hex(upper_u);
   row.df_half_hex=num2hex(a);
   row.betaln_hex=num2hex(betaln(a,0.5));
   row.gammaln_df_half_hex=num2hex(gammaln(a));
   row.gammaln_half_hex=num2hex(gammaln(0.5));
   row.gammaln_df_half_plus_half_hex=num2hex(gammaln(a+0.5));
   row.log_lower_x_hex=num2hex(log(lower_x));
   row.log_upper_u_hex=num2hex(log(upper_u));
   row.log1p_negative_lower_x_hex=num2hex(log1p(-lower_x));
   row.log1p_negative_upper_u_hex=num2hex(log1p(-upper_u));
   row.source_betainc_lower_hex=num2hex(betainc(lower_x,a,0.5));
   row.source_betainc_upper_hex=num2hex(betainc(upper_u,0.5,a,'upper'));
   row.source_tcdf_negative_hex=num2hex(2*tcdf(-t,dfe));
   records(end+1)=row; %#ok<AGROW>
  end
 end
 fprintf('DISCLOSED original MATLAB R2026b Student-t stages rep %d/2 complete\n',rep);
end
report=struct('classification','ORIGINAL_MATHWORKS_R2026B_V11_DISCLOSED_STUDENT_T_STAGES_ONLY',...
 'release',version('-release'),'matlab_version',version,...
 'computer',computer,'mkl_cbwr',getenv('MKL_CBWR'),...
 'max_num_comp_threads',maxNumCompThreads,'original_source_unmodified',true,...
 'original_repetitions',2,'original_case_count',480,'original_coef_count',2,...
 'raw_input_sha256','1144418910dc6a81ba3b98f9540fe914ac796d9a9bab25ce75f6c1ef2ace2f53',...
 'rows',records);
out=getenv('V11_DISCLOSED_STUDENT_T_OUTPUT');assert(~isempty(out));
fd=fopen(fullfile(root,out),'w');assert(fd>0);clean=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
end
