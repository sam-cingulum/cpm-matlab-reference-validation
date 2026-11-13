function run_original_v11_disclosed_inference()
% Genuine R2026b, ORIGINAL UNMODIFIED robustfit on ALREADY REVEALED V11 raw.
% THIS IS A RETROSPECTIVE PROBE, NOT A NEW SOURCE-UNSEEN CERTIFICATION.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
v11=fullfile(root,'..','matlab_robustfit_end_to_end_source_unseen_480_v11');
raw=jsondecode(fileread(fullfile(v11,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_RAW_XY_FULL_ROBUSTFIT_480_V11_SOURCE_UNSEEN'));
assert(raw.seed==202611131963 && numel(raw.cases)==480);
records=struct('id',{},'original_rep',{},'n',{},...
 'original_fieldnames',{},'beta_hex',{},'covb_col_major_hex',{},...
 'coeffcorr_col_major_hex',{},'se_hex',{},'t_hex',{},'p_hex',{},...
 'resid_hex',{},'rstud_hex',{},'dfe_hex',{},'Rtol_col_major_hex',{},...
 'tcdf_negative_twosided_hex',{},'tcdf_positive_complement_twosided_hex',{},...
 'betainc_twosided_hex',{},'betainc_complement_small_hex',{},...
 'betainc_upper_small_hex',{},'betainc_complement_scaled_hex',{});
for rep=1:2
 for i=1:480
  c=raw.cases(i);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
  x=x(:);y=y(:);assert(numel(x)==c.n && numel(y)==c.n);
  [b,st]=robustfit(x,y); % untouched vendor Statistics Toolbox function
  row=struct();row.id=c.id;row.original_rep=rep;row.n=double(c.n);
  row.original_fieldnames=fieldnames(st);
  row.beta_hex=cellstr(num2hex(b(:)));
  row.covb_col_major_hex=cellstr(num2hex(st.covb(:)));
  row.coeffcorr_col_major_hex=cellstr(num2hex(st.coeffcorr(:)));
  row.se_hex=cellstr(num2hex(st.se(:)));
  row.t_hex=cellstr(num2hex(st.t(:)));
  row.p_hex=cellstr(num2hex(st.p(:)));
  row.resid_hex=cellstr(num2hex(st.resid(:)));
  row.rstud_hex=cellstr(num2hex(st.rstud(:)));
  row.dfe_hex=num2hex(st.dfe);
  row.Rtol_col_major_hex=cellstr(num2hex(st.Rtol(:)));
  row.tcdf_negative_twosided_hex=cellstr(num2hex(2*tcdf(-abs(st.t(:)),st.dfe)));
  row.tcdf_positive_complement_twosided_hex=cellstr(num2hex(2*(1-tcdf(abs(st.t(:)),st.dfe))));
  row.betainc_twosided_hex=cellstr(num2hex(betainc(st.dfe./(st.dfe+st.t(:).^2),st.dfe/2,0.5)));
  u=(st.t(:).^2)./(st.dfe+st.t(:).^2);
  row.betainc_complement_small_hex=cellstr(num2hex(1-betainc(u,0.5,st.dfe/2)));
  row.betainc_upper_small_hex=cellstr(num2hex(betainc(u,0.5,st.dfe/2,'upper')));
  scaled=abs(st.t(:))./sqrt(st.dfe);
  uscaled=(scaled.^2)./(1+scaled.^2);
  row.betainc_complement_scaled_hex=cellstr(num2hex(1-betainc(uscaled,0.5,st.dfe/2)));
  records(end+1)=row; %#ok<AGROW>
 end
 fprintf('GENUINE DISCLOSED V11 R2026b full inference %d / 2 repetitions complete\n',rep);
end
report=struct('classification','ORIGINAL_MATHWORKS_R2026B_V11_DISCLOSED_FORENSICS_ONLY',...
 'release',version('-release'),'matlab_version',version,'computer',computer,...
 'mkl_cbwr',getenv('MKL_CBWR'),'max_num_comp_threads',maxNumCompThreads,...
 'case_count',480,'repetitions',2,'original_robustfit_unchanged',true,...
 'raw_input_sha256','1144418910dc6a81ba3b98f9540fe914ac796d9a9bab25ce75f6c1ef2ace2f53',...
 'records',records);
out=getenv('V11_DISCLOSED_INFERENCE_OUTPUT');assert(~isempty(out));
f=fopen(fullfile(root,out),'w');assert(f>0);clean=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(report));
end
