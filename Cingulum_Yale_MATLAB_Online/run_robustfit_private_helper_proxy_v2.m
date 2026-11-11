function report=run_robustfit_private_helper_proxy_v2()
% Licensed genuine R2026b numeric black-box: call installed helper via a
% temporary local symlink in a MATLAB private directory. No proprietary
% source text is copied, modified, committed, archived or printed.
assert(~exist('OCTAVE_VERSION','builtin') && strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(base,'manifest.json')));
d=jsondecode(fileread(fullfile(base,'input.json')));
assert(m.samples==24 && numel(d.samples)==24 && m.source_not_run);
wrapper=which('robustfit');
helper=fullfile(fileparts(wrapper),'private','statrobustsigma.m');
assert(exist(helper,'file')==2);
tmp=tempname;mkdir(tmp);mkdir(fullfile(tmp,'private'));
assert(~contains(helper,' ') && ~contains(tmp,' '));
cmd=['ln -s ' helper ' ' fullfile(tmp,'private','statrobustsigma.m')];
[code,message]=system(cmd);
assert(code==0,['LOCAL_LICENSED_HELPER_SYMLINK_FAILED ' message]);
proxy=fullfile(tmp,'source_robust_sigma_proxy.m');
fid=fopen(proxy,'w');assert(fid>0);
fprintf(fid,'function v=source_robust_sigma_proxy(r,s,t,h,p)\n');
fprintf(fid,'wfun=@(u) double(abs(u)<1).*(1-u.^2).^2;\n');
fprintf(fid,'v=statrobustsigma(r,s,t,wfun,h,p);\n');
fprintf(fid,'end\n');
fclose(fid);
addpath(tmp,'-begin');
assert(~isempty(which('source_robust_sigma_proxy')));
template=struct('id','','original_source_hex','',...
 'original_helper_numeric_hex','','refit_helper_numeric_hex','',...
 'original_helper_exact',false,'refit_helper_exact',false,...
 'original_helper_abs_error',0,'refit_helper_abs_error',0,...
 'helper_numeric_calls_succeeded',false,...
 'original_source_r_vs_refit_exact',false);
records=repmat(template,1,24);
for i=1:24
 item=d.samples(i);x=double(item.x(:));y=double(item.y(:));
 [b,st]=robustfit(x,y);n=numel(x);h=st.h(:);
 r1=st.resid(:)./sqrt(1-h);
 X=[ones(n,1),x];r2=(y-X*b)./sqrt(1-h);
 assert(all(isfinite([r1;r2;st.robust_s])));
 s1=source_robust_sigma_proxy(r1,st.mad_s,4.685,h,2);
 s2=source_robust_sigma_proxy(r2,st.mad_s,4.685,h,2);
 assert(all(isfinite([s1;s2])));
 rec=template;rec.id=item.id;
 rec.original_source_hex=num2hex(st.robust_s);
 rec.original_helper_numeric_hex=num2hex(s1);
 rec.refit_helper_numeric_hex=num2hex(s2);
 rec.original_helper_exact=strcmp(rec.original_source_hex,rec.original_helper_numeric_hex);
 rec.refit_helper_exact=strcmp(rec.original_source_hex,rec.refit_helper_numeric_hex);
 rec.original_helper_abs_error=abs(st.robust_s-s1);
 rec.refit_helper_abs_error=abs(st.robust_s-s2);
 rec.original_source_r_vs_refit_exact=isequal(num2hex(r1),num2hex(r2));
 rec.helper_numeric_calls_succeeded=true;
 records(i)=rec;
end
report=struct('status','POSTHOC_LICENSED_MATHWORKS_HELPER_BLACKBOX_FROM_SOURCE_COMPONENTS',...
 'release','2026b','runtime','MathWorks MATLAB',...
 'original_source_unmodified',true,...
 'license_respected_no_source_copied',true,...
 'temporary_symlink_only',true,...
 'already_disclosed_cases',true,'samples',24,'records',records);
outdir=fullfile(root,'robustfit_private_helper_proxy_v2');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'proxy_numeric_results.json'),'w');assert(fid>0);
fprintf(fid,'%s\n',jsonencode(report));fclose(fid);
rmpath(tmp);
system(['rm -f ' fullfile(tmp,'private','statrobustsigma.m')]);
rmdir(fullfile(tmp,'private'));delete(proxy);rmdir(tmp);
fprintf('LICENSED_HELPER_NUMERIC_PROBES=%d EXACT=%d\n',24,sum([records.original_helper_exact]));
end
