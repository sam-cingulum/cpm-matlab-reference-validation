function report=run_qr_t_conditional_source_unseen_v1()
% Original unmodified genuine MathWorks R2026b source oracle, frozen new
% synthetic x/y. Source outputs include R, s, slope, covariance, SE and t.
% NO Rust candidate calculations, forecasts or proprietary source extracted.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'qr_t_conditional_prospective_v1');
manifest=jsondecode(fileread(fullfile(base,'manifest.json')));
inputs=jsondecode(fileread(fullfile(base,'input.json')));
assert(strcmp(manifest.experiment_id,'r2026b-qr-covariance-conditional-source-unseen-20261112-v1'));
assert(strcmp(inputs.experiment_id,manifest.experiment_id));
assert(manifest.source_not_run_at_freeze);
assert(manifest.conditional_source_components_only);
assert(manifest.cases==80 && numel(inputs.cases)==80);
template=struct('id','','n',0,'R',zeros(2,2),'R11_hex','',...
 'R12_hex','','R21_hex','','R22_hex','',...
 'scale_hex','','slope_hex','','intercept_hex','',...
 'source_covb22_hex','','source_se2_hex','','source_t2_hex','',...
 'original_R_is_upper',false,'original_R_is_lower',false);
rows=repmat(template,1,80);
for k=1:80
 d=inputs.cases(k);
 x=double(d.x(:));y=double(d.y(:));
 assert(numel(x)==d.n && numel(y)==d.n);
 [beta,st]=robustfit(x,y);
 assert(isequal(size(st.R),[2 2]) && isequal(size(st.covb),[2 2]));
 assert(all(isfinite([beta(:);st.s;st.robust_s;st.covb(2,2);st.se(2);st.t(2)])));
 rec=template;
 rec.id=d.id;rec.n=d.n;
 rec.R=st.R;rec.R11_hex=num2hex(st.R(1,1));
 rec.R12_hex=num2hex(st.R(1,2));
 rec.R21_hex=num2hex(st.R(2,1));
 rec.R22_hex=num2hex(st.R(2,2));
 rec.scale_hex=num2hex(st.s);
 rec.slope_hex=num2hex(beta(2));
 rec.intercept_hex=num2hex(beta(1));
 rec.source_covb22_hex=num2hex(st.covb(2,2));
 rec.source_se2_hex=num2hex(st.se(2));
 rec.source_t2_hex=num2hex(st.t(2));
 rec.original_R_is_upper=st.R(2,1)==0;
 rec.original_R_is_lower=st.R(1,2)==0;
 rows(k)=rec;
end
assert(numel(rows)==80);
report=struct('status','GENUINE_SOURCE_UNSEEN_R2026B_QR_T_CONDITIONAL_ORIGINAL',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'original_robustfit_unmodified',true,'no_Rust_forecasts_read',true,...
 'source_inputs_previously_unseen',true,...
 'experiment_id',manifest.experiment_id,...
 'input_sha256',manifest.frozen_input_sha256,'cases',80,...
 'records',rows);
outdir=fullfile(root,'qr_t_conditional_source_original_v1');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'genuine_original_source_qr_t.json'),'w');assert(fid>0);
handle=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('MATHWORKS_R2026B_ORIGINAL_QR_SOURCE_UNSEEN_CASES=%d\n',80);
end
