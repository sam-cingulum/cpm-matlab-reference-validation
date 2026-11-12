function report=run_robustfit_covariance_reduction_v1()
% Genuine R2026b original robustfit numeric observations, source unchanged.
% Goal: map the exact independent covariance/t path for pivoted, rescaled
% and high-leverage predictors. No MathWorks implementation text extracted.
assert(exist('OCTAVE_VERSION','builtin')==0 && strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
p=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(p,'manifest.json')));
d=jsondecode(fileread(fullfile(p,'input.json')));
assert(m.samples==24 && numel(d.samples)==24 && m.source_not_run);
template=struct('id','','n',0,'R',zeros(2),'R_rowmajor_hex',{{}},...
 'covb',zeros(2),'covb_rowmajor_hex',{{}},...
 'scale_hex','','beta_hex',{{}},'se_hex',{{}},'t_hex',{{}},...
 'covb_candidate_invR_invRtranspose',zeros(2),...
 'covb_candidate_invRtranspose_invR',zeros(2),...
 'covb_candidate_direct_normal_inverse',zeros(2),...
 'covb_candidate_s_times_invR',zeros(2),...
 'matrix_identity_R_inverse_R',0,...
 'original_R_is_strictly_upper_triangular',false);
records=repmat(template,1,24);
for k=1:numel(d.samples)
 data=d.samples(k);x=double(data.x(:));y=double(data.y(:));
 [beta,st]=robustfit(x,y);
 assert(isequal(size(st.R),[2 2]) && isequal(size(st.covb),[2 2]));
 R=st.R;s=st.s;V=st.covb;
 H=inv(R);
 c1=(H*H')*(s*s);
 c2=(H'*H)*(s*s);
 c3=inv(R'*R)*(s*s);
 c4=(s*H)*(s*H)';
 rec=template;
 rec.id=data.id;rec.n=numel(x);rec.R=R;rec.covb=V;
 rec.R_rowmajor_hex={num2hex(R(1,1)),num2hex(R(1,2)),num2hex(R(2,1)),num2hex(R(2,2))};
 rec.covb_rowmajor_hex={num2hex(V(1,1)),num2hex(V(1,2)),num2hex(V(2,1)),num2hex(V(2,2))};
 rec.scale_hex=num2hex(s);
 rec.beta_hex={num2hex(beta(1)),num2hex(beta(2))};
 rec.se_hex={num2hex(st.se(1)),num2hex(st.se(2))};
 rec.t_hex={num2hex(st.t(1)),num2hex(st.t(2))};
 rec.covb_candidate_invR_invRtranspose=c1;
 rec.covb_candidate_invRtranspose_invR=c2;
 rec.covb_candidate_direct_normal_inverse=c3;
 rec.covb_candidate_s_times_invR=c4;
 rec.matrix_identity_R_inverse_R=norm(R*H-eye(2),'fro');
 rec.original_R_is_strictly_upper_triangular=R(2,1)==0;
 records(k)=rec;
end
assert(numel(records)==24);
report=struct('status','GENUINE_R2026B_SOURCE_R_QR_COVARIANCE_NUMERICS',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'original_robustfit_unmodified',true,'previously_disclosed_input',true,...
 'no_original_MathWorks_source_extraction',true,...
 'input_sha256',m.input_sha256,'cases',24,'records',records);
outdir=fullfile(root,'robustfit_covariance_reduction_v1');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'source_covariance_matrix_observations.json'),'w');
assert(fid>0);cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('GENUINE_R2026B_QR_COVARIANCE_SOURCE_CASES=%d\n',numel(records));
end
