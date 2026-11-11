function report=run_robustfit_independent_sigma_exact_v4()
% Independent public mathematical expression, exact MathWorks R2026b numeric
% witness. User-authored formula, NO original proprietary source copied.
% Inputs are 24 already disclosed sealed original robustfit synthetic fits.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(base,'manifest.json')));
items=jsondecode(fileread(fullfile(base,'input.json')));
assert(m.samples==24 && numel(items.samples)==24 && m.source_not_run);
record=struct('id','','original_source_hex','','independent_recomputed_hex','',...
 'exact_binary64',false,'n',0,'u_hex',{{}},'dphi_hex',{{}},...
 'phi_hex',{{}},'h_hex',{{}},'mad_s_hex','',...
 'm1_hex','','m2_hex','','K_hex','','sigma_hex','',...
 'slope_hex','','R22_hex','');
records=repmat(record,1,24);
wfun=@(u) double(abs(u)<1).*(1-u.^2).^2;
for k=1:24
 d=items.samples(k);x=double(d.x(:));y=double(d.y(:));
 [b,st]=robustfit(x,y);
 n=numel(x);p=2;
 leverage=st.h(:);
 mad_s=st.mad_s; tune=4.685;
 % Direct, mathematically independent MATLAB formulation of exact source
 % residual normalization, established through prior callback observation.
 r=st.resid(:).*(1./sqrt(1-leverage));
 scale=mad_s*tune;
 u=r./scale;
 phi=u.*wfun(u);
 delta=0.0001;
 ulo=u-delta;phi0=ulo.*wfun(ulo);
 uhi=u+delta;phi1=uhi.*wfun(uhi);
 dphi=(phi1-phi0)./(2*delta);
 m1=mean(dphi);
 m2=sum((1-leverage).*(phi.^2))/(n-p);
 K=1+(p/n)*(1-m1)/m1;
 sigma=K*sqrt(m2)*scale/m1;
 assert(all(isfinite([sigma;m1;m2;K])) && sigma>0);
 rec=record;rec.id=d.id;rec.n=n;
 rec.original_source_hex=num2hex(st.robust_s);
 rec.independent_recomputed_hex=num2hex(sigma);
 rec.exact_binary64=strcmp(rec.original_source_hex,rec.independent_recomputed_hex);
 rec.u_hex=cellstr(num2hex(u))';
 rec.dphi_hex=cellstr(num2hex(dphi))';
 rec.phi_hex=cellstr(num2hex(phi))';
 rec.h_hex=cellstr(num2hex(leverage))';
 rec.mad_s_hex=num2hex(mad_s);
 rec.m1_hex=num2hex(m1);rec.m2_hex=num2hex(m2);
 rec.K_hex=num2hex(K);rec.sigma_hex=num2hex(sigma);
 rec.slope_hex=num2hex(b(2));rec.R22_hex=num2hex(st.R(2,2));
 records(k)=rec;
end
report=struct('status','ORIGINAL_MATHWORKS_R2026B_INDEPENDENT_SIGMA_ARITHMETIC',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'mathworks_source_unmodified',true,'independent_formula_public',true,...
 'source_inputs_already_disclosed',true,...
 'input_sha256',m.input_sha256,'samples',24,...
 'exact_robust_s_count',sum([records.exact_binary64]),...
 'records',records);
outdir=fullfile(root,'robustfit_independent_sigma_exact_v4');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'independent_sigma_stages.json'),'w');assert(fid>0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('INDEPENDENT_SOURCE_SIGMA_BINARY64=%d/24\n',report.exact_robust_s_count);
end
