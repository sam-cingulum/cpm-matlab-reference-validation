function out=run_robustfit_source_fd_prospective_v1()
% Exact genuine MathWorks R2026b robustfit output for entirely frozen input.
% No Rust forecast is read or used in MATLAB fitting. Original mathworks
% robustfit is unchanged; no proprietary implementation source copied.
assert(~exist('OCTAVE_VERSION','builtin'));
assert(strcmp(version('-release'),'2026b'));
assert(~isempty(which('robustfit')));
root=fileparts(mfilename('fullpath'));
expdir=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(expdir,'manifest.json')));
assert(strcmp(m.experiment_id,'mathworks-robustfit-source-fd-prospective-20261111-v1'));
assert(strcmp(m.source_commit,'708999b8bb27ae69722775c323da9f14ef6732c7'));
assert(m.samples==24 && m.source_not_run);
data=jsondecode(fileread(fullfile(expdir,'input.json')));
assert(numel(data.samples)==24);
files_out=fullfile(root,'robustfit_source_fd_original_v1');
if ~exist(files_out,'dir'),mkdir(files_out);end
template=struct('id','','n',0,'slope',0,'intercept',0,'ols_s',0,...
 'mad_s',0,'robust_s',0,'effective_s',0,'t',0,'p',0,...
 'slope_hex','','intercept_hex','','ols_s_hex','','mad_s_hex','',...
 'robust_s_hex','','effective_s_hex','','t_hex','','p_hex','',...
 'R22_hex','','se2_hex','','covb22_hex','',...
 'original_matlab_function','robustfit');
records=repmat(template,1,24);
for k=1:24
 d=data.samples(k);x=double(d.x(:));y=double(d.y(:));
 assert(numel(x)==numel(y) && numel(x)>=10 && all(isfinite(x)) && all(isfinite(y)));
 [b,st]=robustfit(x,y);
 assert(numel(b)==2 && all(isfinite([b(:);st.robust_s;st.s;st.se(2);st.t(2)])));
 r=template;
 r.id=d.id;r.n=numel(x);r.slope=b(2);r.intercept=b(1);
 r.ols_s=st.ols_s;r.mad_s=st.mad_s;
 r.robust_s=st.robust_s;r.effective_s=st.s;
 r.t=st.t(2);r.p=st.p(2);
 r.slope_hex=num2hex(r.slope);r.intercept_hex=num2hex(r.intercept);
 r.ols_s_hex=num2hex(r.ols_s);r.mad_s_hex=num2hex(r.mad_s);
 r.robust_s_hex=num2hex(r.robust_s);r.effective_s_hex=num2hex(r.effective_s);
 r.t_hex=num2hex(r.t);r.p_hex=num2hex(r.p);
 r.R22_hex=num2hex(st.R(2,2));
 r.se2_hex=num2hex(st.se(2));r.covb22_hex=num2hex(st.covb(2,2));
 records(k)=r;
end
assert(numel(records)==24);
out=struct('runtime','MathWorks MATLAB','release','2026b',...
 'status','GENUINE_SOURCE_ORIGINAL_ROBUSTFIT_R2026B_DIRECT',...
 'original_function_unmodified',true,...
 'no_rust_models_read',true,'source_commit',m.source_commit,...
 'experiment_id',m.experiment_id,'sample_count',24,...
 'input_sha256',m.input_sha256,...
 'rust_pre_frozen_sha256',m.rust_forecast_sha256,...
 'source_original_results',records);
p=fullfile(files_out,'original_robustfit_source_fd_v1.json');
fid=fopen(p,'w');assert(fid>0);onend=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(out));
fprintf('MATHWORKS_R2026B_UNMODIFIED_ROBUSTFIT_COMPLETED=%d\n',numel(records));
end
