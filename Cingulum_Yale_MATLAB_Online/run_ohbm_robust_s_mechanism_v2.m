function report=run_ohbm_robust_s_mechanism_v2()
% Original-data-only R2026b retrospective black-box mechanism experiment.
% Never reconstruct new predictions or claim a prospective binary64 pass.
% Inspect helper *metadata only*; never export or print MathWorks source text.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'ohbm_robust_option3_v1');
manifest=jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(manifest.experiment_id,'ohbm-original-robust-option3-20261111-v1'));
assert(strcmp(manifest.source_commit,'708999b8bb27ae69722775c323da9f14ef6732c7'));
outdir=fullfile(root,'ohbm_robust_s_mechanism_v2');
if ~exist(outdir,'dir'),mkdir(outdir);end
wrapper=which('robustfit');assert(~isempty(wrapper));
helper=fullfile(fileparts(wrapper),'private','statrobustfit.m');
ishelper=exist(helper,'file')==2;
meta=struct('wrapper_exists',true,'private_helper_exists',ishelper,...
 'helper_line_count',0,'helper_bytes',0,'has_robust_sigma_identifier',false,...
 'has_psi_identifier',false,'has_lambda_identifier',false,...
 'has_sqrt_eps_identifier',false,'has_mad_identifier',false,...
 'has_Street_reference',false);
if ishelper
 s=fileread(helper);low=lower(s);
 meta.helper_line_count=numel(regexp(s,'\n','match'))+1;
 meta.helper_bytes=numel(s);
 meta.has_robust_sigma_identifier=contains(low,'robust_s');
 meta.has_psi_identifier=contains(low,'psi');
 meta.has_lambda_identifier=contains(low,'lambda');
 meta.has_sqrt_eps_identifier=contains(low,'sqrt(eps');
 meta.has_mad_identifier=contains(low,'madsigma');
 meta.has_Street_reference=contains(low,'street');
 clear s low; % Do not export MathWorks source.
end
names={'robust_baseline_n31_d6_s181401',...
       'robust_outliers_n35_d6_s181403',...
       'robust_rescaled_n43_d7_s181409'};
template=struct('name','','heldout_zero_based',0,'edge_zero_based',[0 0],...
 'n',0,'source_robust_s',0,'source_robust_s_hex','',...
 'default_vs_explicit_bisquare_exact',false,...
 'default_vs_custom_weight_binary64_scale',false,...
 'source_t',0,'source_t_hex','',...
 'custom_robust_s',0,'custom_robust_s_abs_diff',0,...
 'custom_robust_s_hex','',...
 'source_t_from_reported_coefficient_and_se_exact',false,...
 'source_t_via_R_based_se_exact',false,...
 'source_t_via_covb_se_exact',false,...
 'absolute_analytic_robust_scale_err',0,...
 'absolute_signed_fd_sqrt_eps_err',0,...
 'absolute_signed_fd_2sqrt_eps_err',0,...
 'absolute_signed_fd_2e8_err',0,...
 'analytic_robust_scale_hex','',...
 'signed_fd_sqrt_eps_hex','',...
 'signed_fd_2sqrt_eps_hex','',...
 'signed_fd_2e8_hex','');
records=repmat(template,1,27);idx=0;
for ci=1:numel(names)
 name=names{ci};d=jsondecode(fileread(fullfile(pack,name,'input.json')));
 n=numel(d.outcomes);outcomes=double(d.outcomes(:));
 mats=double(d.subject_matrices);
 heldouts=unique([1,ceil(n/2),n]);coords=[1,2;2,4;1,6];
 for held=heldouts
  y=outcomes;y(held)=[];
  for ee=1:size(coords,1)
   ii=coords(ee,1);jj=coords(ee,2);
   x=squeeze(mats(:,ii,jj));x(held)=[];
   [bet,st]=robustfit(x,y);
   [be,se]=robustfit(x,y,'bisquare',4.685);
   [bc,sc]=robustfit(x,y,@(v) double(abs(v)<1).*(1-v.^2).^2,4.685);
   s=st.robust_s;
   assert(all(isfinite([bet(:);be(:);bc(:);s;sc.robust_s;st.t(2)])));
   exact_explicit=strcmp(num2hex(s),num2hex(se.robust_s))&&...
       isequal(num2hex(bet),num2hex(be));
   exact_custom=strcmp(num2hex(s),num2hex(sc.robust_s));
   nfit=numel(x);h=st.h(:);
   u=st.resid(:)./(4.685*st.mad_s*sqrt(1-h));
   psi=@(z) (abs(z)<1).*z.*(1-z.^2).^2;
   use=abs(u)<1;
   dp=zeros(size(u));
   dp(use)=(1-u(use).^2).*(1-5*u(use).^2);
   a=mean(dp);
   b=sum((1-h).*psi(u).^2)/(nfit-2);
   candidate=@(aa) (1+(2/nfit)*(1-aa)/aa)*sqrt(b)*(4.685*st.mad_s)/aa;
   an=candidate(a);
   step=sqrt(eps('double'));
   pval=psi(abs(u));
   afd1=mean((psi(abs(u)+step)-pval)/step);
   afd2=mean((psi(abs(u)+2*step)-pval)/(2*step));
   afd3=mean((psi(abs(u)+2e-8)-pval)/(2e-8));
   sd1=candidate(afd1);sd2=candidate(afd2);sd3=candidate(afd3);
   se_qr=st.s/abs(st.R(2,2));
   covariance_slope=st.covb(2,2);
   idx=idx+1;rec=template;rec.name=name;
   rec.heldout_zero_based=held-1;rec.edge_zero_based=[ii-1 jj-1];
   rec.n=nfit;rec.source_robust_s=s;rec.source_robust_s_hex=num2hex(s);
   rec.default_vs_explicit_bisquare_exact=exact_explicit;
   rec.default_vs_custom_weight_binary64_scale=exact_custom;
   rec.source_t=st.t(2);rec.source_t_hex=num2hex(st.t(2));
   rec.custom_robust_s=sc.robust_s;rec.custom_robust_s_hex=num2hex(sc.robust_s);
   rec.custom_robust_s_abs_diff=abs(sc.robust_s-s);
   rec.source_t_from_reported_coefficient_and_se_exact=strcmp(...
     num2hex(bet(2)/st.se(2)),num2hex(st.t(2)));
   rec.source_t_via_R_based_se_exact=strcmp(...
     num2hex(bet(2)/se_qr),num2hex(st.t(2)));
   rec.source_t_via_covb_se_exact=strcmp(...
     num2hex(bet(2)/sqrt(covariance_slope)),num2hex(st.t(2)));
   rec.absolute_analytic_robust_scale_err=abs(an-s);
   rec.absolute_signed_fd_sqrt_eps_err=abs(sd1-s);
   rec.absolute_signed_fd_2sqrt_eps_err=abs(sd2-s);
   rec.absolute_signed_fd_2e8_err=abs(sd3-s);
   rec.analytic_robust_scale_hex=num2hex(an);
   rec.signed_fd_sqrt_eps_hex=num2hex(sd1);
   rec.signed_fd_2sqrt_eps_hex=num2hex(sd2);
   rec.signed_fd_2e8_hex=num2hex(sd3);
   records(idx)=rec;
  end
 end
end
assert(idx==27);
report=struct('runtime','MathWorks MATLAB','release','2026b',...
 'status','POSTHOC_DISCLOSED_27_FITS_NOT_SOURCE_CERTIFICATION',...
 'source_commit',manifest.source_commit,'source_unmodified',true,...
 'proprietary_code_copied',false,'helper_metadata_only',meta,...
 'probe_count',idx,'records',records);
outfile=fullfile(outdir,'genuine_mathworks_robust_s_mechanism_v2.json');
fid=fopen(outfile,'w');assert(fid>0);clean=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('MATLAB_ONLY_OBSERVABLE_SIGMA_T_FORENSIC_COMPLETED_27\n');
end
