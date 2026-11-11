function report=run_robustfit_private_helper_blackbox_v1()
% Attempt numeric black-box invocation of documented local installed helper.
% Never read or export helper's licensed source text, only numeric outputs.
assert(~exist('OCTAVE_VERSION','builtin') && strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
data=jsondecode(fileread(fullfile(root,'robustfit_source_fd_prospective_v1','input.json')));
m=jsondecode(fileread(fullfile(root,'robustfit_source_fd_prospective_v1','manifest.json')));
assert(numel(data.samples)==24 && m.source_not_run);
wrapper=which('robustfit');priv=fullfile(fileparts(wrapper),'private');
helper=fullfile(priv,'statrobustsigma.m');assert(exist(helper,'file')==2);
addpath(priv,'-begin');
can_call=~isempty(which('statrobustsigma'));
printable=struct('id','','source_robust_s_hex','',...
  'helper_callable',false,'helper_error_identifier','',...
  'helper_with_source_residual_bits_exact',false,...
  'helper_with_refit_residual_bits_exact',false,...
  'helper_with_source_residual_abs_error',NaN,...
  'helper_with_refit_residual_abs_error',NaN,...
  'source_residual_v_refit_residual_bits_equal',false,...
  'source_residual_v_refit_residual_max_abs_diff',NaN);
records=repmat(printable,1,24);
for i=1:24
 d=data.samples(i);x=double(d.x(:));y=double(d.y(:));
 [b,stats]=robustfit(x,y);
 n=numel(x);xx=[ones(n,1) x];
 observed=double(stats.resid(:));
 refit=y-xx*b;
 h=double(stats.h(:));
 r_source=observed./sqrt(1-h);
 r_refit=refit./sqrt(1-h);
 rec=printable;rec.id=d.id;rec.source_robust_s_hex=num2hex(stats.robust_s);
 rec.source_residual_v_refit_residual_bits_equal=isequal(num2hex(observed),num2hex(refit));
 rec.source_residual_v_refit_residual_max_abs_diff=max(abs(observed-refit));
 rec.helper_callable=can_call;
 if can_call
  % Mathematically specified bisquare, no MathWorks source duplicated.
  fun=@(u) double(abs(u)<1).*(1-u.^2).^2;
  try
   t=4.685;rank_x=2;
   sigma1=statrobustsigma(r_source,stats.mad_s,t,fun,h,rank_x);
   sigma2=statrobustsigma(r_refit,stats.mad_s,t,fun,h,rank_x);
   rec.helper_with_source_residual_bits_exact=strcmp(num2hex(sigma1),num2hex(stats.robust_s));
   rec.helper_with_refit_residual_bits_exact=strcmp(num2hex(sigma2),num2hex(stats.robust_s));
   rec.helper_with_source_residual_abs_error=abs(sigma1-stats.robust_s);
   rec.helper_with_refit_residual_abs_error=abs(sigma2-stats.robust_s);
  catch ME
   rec.helper_error_identifier=ME.identifier;
  end
 end
 records(i)=rec;
end
report=struct('status','POSTHOC_HELPER_BLACKBOX_NO_PROPRIETARY_SOURCE',...
 'release','2026b','runtime','MathWorks MATLAB',...
 'already_disclosed_cases',true,...
 'original_unmodified',true,...
 'helper_path_available',can_call,...
 'samples',24,'records',records);
folder=fullfile(root,'robustfit_private_helper_blackbox_v1');
if ~exist(folder,'dir'),mkdir(folder);end
fid=fopen(fullfile(folder,'helper_probe.json'),'w');assert(fid>0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('ORIGINAL_MATHWORKS_PRIVATE_HELPER_NUMERIC_PROBES_DONE=%d\n',24);
end
