function report=run_robustfit_u_exact_arithmetic_v1()
% Black-box source internal normalized residuals, 24 ALREADY-disclosed fits.
% Independent candidate arithmetic operations; no MathWorks source extracted.
assert(exist('OCTAVE_VERSION','builtin')==0 && strcmp(version('-release'),'2026b'));
base=fileparts(mfilename('fullpath'));
fixture=fullfile(base,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(fixture,'manifest.json')));
data=jsondecode(fileread(fullfile(fixture,'input.json')));
assert(m.samples==24 && numel(data.samples)==24 && m.source_not_run);
global CINGULUM_EXACT_U_CAPTURE;
names={'reported_u','resid_over_combined','resid_over_scale_then_h',...
 'resid_times_leverage_reciprocal','adjusted_times_scale_reciprocal',...
 'resid_over_h_then_mad_then_tune','resid_over_tune_then_mad_then_h',...
 'resid_over_h_mad_then_tune','resid_over_mad_tune_then_h',...
 'resid_over_h_tune_then_mad','resid_over_mad_h_then_tune',...
 'resid_over_scale_h_reciprocal'};
template=struct('id','','n',0,'original_vs_callback_sigma_exact',false,...
 'original_vs_callback_beta_exact',false,'callback_calls',0,...
 'source_internal_u_hex',{{}},'reported_resid_hex',{{}},...
 'reported_h_hex',{{}},'reported_mad_s_hex','','original_slope_hex','',...
 'original_intercept_hex','','original_robust_s_hex','','original_t_hex','',...
 'candidate_exact_element_counts',zeros(1,12),...
 'best_candidate_count',0);
records=repmat(template,1,24);
for k=1:24
 item=data.samples(k);x=double(item.x(:));y=double(item.y(:));
 [beta,st]=robustfit(x,y);
 CINGULUM_EXACT_U_CAPTURE={};
 [be,ce]=robustfit(x,y,@capture_robustfit_weights,4.685);
 calls=CINGULUM_EXACT_U_CAPTURE;assert(numel(calls)>=3);
 u=calls{end-2}(:);h=double(st.h(:));r=double(st.resid(:));
 n=numel(x);assert(numel(u)==n && numel(h)==n && numel(r)==n);
 scale=double(st.mad_s);tune=4.685;
 hs=sqrt(1-h);stune=scale*tune;
 candidate=cell(1,12);
 candidate{1}=(r./hs)./stune;
 candidate{2}=r./(hs.*stune);
 candidate{3}=(r./stune)./hs;
 candidate{4}=(r.*(1./hs))./stune;
 candidate{5}=(r./hs).*(1./stune);
 candidate{6}=((r./hs)./scale)./tune;
 candidate{7}=((r./tune)./scale)./hs;
 candidate{8}=r./((hs.*scale)*tune);
 candidate{9}=r./((hs.*stune));
 candidate{10}=r./((hs.*tune)*scale);
 candidate{11}=r./((scale.*hs)*tune);
 candidate{12}=r.*(1./(hs.*stune));
 exact=zeros(1,12);
 hu=cellstr(num2hex(u));
 for c=1:12
  z=candidate{c};assert(numel(z)==n && all(isfinite(z)));
  exact(c)=sum(strcmp(cellstr(num2hex(z(:))),hu));
 end
 rec=template;rec.id=item.id;rec.n=n;
 rec.original_vs_callback_sigma_exact=strcmp(num2hex(st.robust_s),num2hex(ce.robust_s));
 rec.original_vs_callback_beta_exact=isequal(num2hex(beta),num2hex(be));
 rec.callback_calls=numel(calls);
 rec.source_internal_u_hex=cellstr(num2hex(u))';
 rec.reported_resid_hex=cellstr(num2hex(r))';
 rec.reported_h_hex=cellstr(num2hex(h))';
 rec.reported_mad_s_hex=num2hex(scale);
 rec.original_slope_hex=num2hex(beta(2));
 rec.original_intercept_hex=num2hex(beta(1));
 rec.original_robust_s_hex=num2hex(st.robust_s);
 rec.original_t_hex=num2hex(st.t(2));
 rec.candidate_exact_element_counts=exact;rec.best_candidate_count=max(exact);
 assert(rec.original_vs_callback_sigma_exact);
 records(k)=rec;
 CINGULUM_EXACT_U_CAPTURE={};
end
assert(numel(records)==24);
report=struct('status','GENUINE_R2026B_INTERNAL_U_SOURCE_NUMERIC_ROUNDING_STUDY',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'source_function_unmodified',true,'no_proprietary_source_exported',true,...
 'source_inputs_previously_disclosed',true,'input_sha256',m.input_sha256,...
 'cpu_architecture',computer('arch'), 'threads',maxNumCompThreads,...
 'candidate_names',{names},'cases',24,'records',records);
outdir=fullfile(base,'robustfit_u_exact_arithmetic_v1');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'source_internal_u_arithmetic.json'),'w');assert(fid>0);
fin=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('SOURCE_INTERNAL_U_CANDIDATES_EXACT_SUMMARY=');
for i=1:12
 fprintf('%d,',sum(arrayfun(@(r)r.candidate_exact_element_counts(i),records)));
end
fprintf('\n');
end

function weights=capture_robustfit_weights(u)
global CINGULUM_EXACT_U_CAPTURE;
CINGULUM_EXACT_U_CAPTURE{end+1}=double(u(:));
weights=double(abs(u)<1).*(1-u.^2).^2;
end
