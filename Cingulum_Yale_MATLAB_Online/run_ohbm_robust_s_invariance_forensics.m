function report = run_ohbm_robust_s_invariance_forensics()
% Post-hoc original MathWorks R2026b *numeric outputs only*.
% Source-invisible prospective OHBM option-3 forecasts were already frozen
% and executed in separate run 42996833958. This diagnostic does NOT
% certify new parity, expose MATLAB proprietary code, or rewrite forecasts.
if exist('OCTAVE_VERSION','builtin'), error('GENUINE_MATHWORKS_REQUIRED'); end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'ohbm_robust_option3_v1');
manifest=jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(manifest.experiment_id,'ohbm-original-robust-option3-20261111-v1'));
src=which('robustfit');
[~,~,ext]=fileparts(src);
assert(~isempty(src),'ROBUSTFIT_NOT_FOUND');
fprintf('MATHWORKS_ROBUSTFIT_PRODUCTION_FUNCTION_EXTENSION %s\n',ext);
outdir=fullfile(root,'ohbm_robust_s_invariance_forensics');
if ~exist(outdir,'dir'),mkdir(outdir);end
names={'robust_baseline_n31_d6_s181401',...
       'robust_outliers_n35_d6_s181403',...
       'robust_rescaled_n43_d7_s181409'};
records=struct('case_name',{},'leftout_zero_based',{},'edge_zero_based',{},...
 'observations',{},'robustfit_s',{},'robustfit_hex',{},...
 'source_scale_sign_reversal',{},'source_scale_predictor_sign_reversal',{},...
 'source_scale_response_offset',{},'source_scale_row_reversal',{},...
 'source_scale_row_reversal_hex',{},...
 'absolute_gsl_analytic_error',{},'absolute_signed_fd_error',{},...
 'relative_gsl_analytic_error',{},...
 'analytic_scale_hex',{},'signed_fd_scale_hex',{},...
 'original_matlab_robustfit_extension',{});
for ci=1:numel(names)
 name=names{ci};meta=manifest.cases.(name);
 data=jsondecode(fileread(fullfile(pack,name,'input.json')));
 n=numel(data.outcomes);
 assert(n==meta.n);
 mats=double(data.subject_matrices);
 assert(size(mats,1)==n);
 d=meta.parcels;
 yi=double(data.outcomes(:));
 folds=unique([1,ceil(n/2),n]);
 edgecoords=[1,2;2,4;1,6];
 for held=folds
  y=yi;y(held)=[];
  for ei=1:size(edgecoords,1)
   row=edgecoords(ei,1);col=edgecoords(ei,2);
   x=double(squeeze(mats(:,row,col)));x(held)=[];
   [b,st]=robustfit(x,y);
   [~,st_flipY]=robustfit(x,-y);
   [~,st_flipX]=robustfit(-x,y);
   [~,st_offsetY]=robustfit(x,y+12.0);
   [~,st_reverse]=robustfit(flipud(x),flipud(y));
   assert(all(isfinite([b(:);st.robust_s;st.s;st.mad_s])));
   nf=numel(x);h=st.h(:);
   u=st.resid(:)./(4.685*st.mad_s*sqrt(1-h));
   inside=abs(u)<1;
   psi=zeros(size(u));
   dpsi=zeros(size(u));
   psi(inside)=u(inside).*(1-u(inside).^2).^2;
   dpsi(inside)=(1-u(inside).^2).*(1-5*u(inside).^2);
   a=mean(dpsi);
   numer=sum((1-h).*psi.^2)/(nf-2);
   candidate=(1+(2/nf)*(1-a)/a)*sqrt(numer)*(4.685*st.mad_s)/a;
   us=u+sign(u)*2e-8;
   psin=zeros(size(u));valid=abs(us)<1;
   psin(valid)=us(valid).*(1-us(valid).^2).^2;
   diffu=sign(u)*2e-8;
   dfd=dpsi;
   idx=diffu~=0;
   dfd(idx)=(psin(idx)-psi(idx))./diffu(idx);
   afd=mean(dfd);
   signedfd=(1+(2/nf)*(1-afd)/afd)*sqrt(numer)*(4.685*st.mad_s)/afd;
   assert(all(isfinite([candidate,signedfd])));
   rec=struct('case_name',name,'leftout_zero_based',held-1,...
      'edge_zero_based',[row-1,col-1],...
      'observations',nf,'robustfit_s',st.robust_s,...
      'robustfit_hex',num2hex(st.robust_s),...
      'source_scale_sign_reversal',st_flipY.robust_s,...
      'source_scale_predictor_sign_reversal',st_flipX.robust_s,...
      'source_scale_response_offset',st_offsetY.robust_s,...
      'source_scale_row_reversal',st_reverse.robust_s,...
      'source_scale_row_reversal_hex',num2hex(st_reverse.robust_s),...
      'absolute_gsl_analytic_error',abs(candidate-st.robust_s),...
      'absolute_signed_fd_error',abs(signedfd-st.robust_s),...
      'relative_gsl_analytic_error',abs(candidate/st.robust_s-1),...
      'analytic_scale_hex',num2hex(candidate),...
      'signed_fd_scale_hex',num2hex(signedfd),...
      'original_matlab_robustfit_extension',ext);
   records(end+1)=rec; %#ok<AGROW>
  end
 end
end
assert(numel(records)==27);
report=struct('runtime','MathWorks MATLAB',...
    'release','2026b','mode','POSTHOC_NUMERICAL_MECHANISM_NOT_NEW_PARITY',...
    'original_unmodified_source_component',true,...
    'original_upstream_commit',manifest.source_commit,...
    'cohort_count',numel(names),'probe_count',numel(records),...
    'robustfit_binary_extension',ext,...
    'records',records);
outfile=fullfile(outdir,'original_mathworks_transformations.json');
fid=fopen(outfile,'w');assert(fid>0);clean=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
end
