function report=run_robustfit_irls_full_recurrence_forensics_v1()
% Genuine MathWorks R2026b unmodified robustfit numeric callback experiment.
% All original x/y cohorts were previously disclosed. Independently rebuild
% the full sequence of weighted regressions, normalized residuals and MAD
% from raw x/y and callback-provided weights only. Original proprietary
% source is not read or transmitted.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
folder=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(folder,'manifest.json')));
dat=jsondecode(fileread(fullfile(folder,'input.json')));
assert(m.samples==24 && numel(dat.samples)==24 && m.source_not_run);
global CINGULUM_R2026B_IRLS_NUMERIC_CAPTURE;
records=struct('id',{},'n',{},'iterations',{},...
 'original_vs_custom_beta_exact',{},...
 'original_vs_custom_robust_s_exact',{},...
 'first_initial_OLS_u_exact_elements',{},...
 'final_last_callback_w_vs_custom_stats_w_exact',{},...
 'final_last_callback_w_vs_original_stats_w_exact',{},...
 'original_vs_custom_final_stats_w_exact',{},...
 'full_recurrence_next_u_exact_elements',{},...
 'full_recurrence_next_u_total_elements',{},...
 'first_initial_mad_hex',{},'first_source_callback_u_hex',{},...
 'initial_OLS_beta_hex',{},'initial_OLS_u_reconstructed_hex',{},...
 'source_original_beta_hex',{},'custom_beta_hex',{},...
 'source_last_callback_w_hex',{},'source_original_stats_w_hex',{},...
 'all_iteration_source_callbacks',{},'independent_recurrence',{},...
 'source_mad_hex',{});
for k=1:24
 q=dat.samples(k);x=double(q.x(:));y=double(q.y(:));n=numel(x);
 X=[ones(n,1),x];
 [b,st]=robustfit(x,y);
 % Independently reconstruct exact source R and h with observed semantics.
 [Q,R,p]=qr(X,'econ','vector');
 Rorig=R;
 if isequal(double(p(:)'),[2 1]),Rorig=R([2 1],[2 1]);end
 assert(isequal(num2hex(st.R),num2hex(Rorig)));
 Z=X/Rorig;
 h=sum(Z.^2,2);
 assert(isequal(num2hex(h),num2hex(st.h)));
 invsqrt_h=1./sqrt(1-h);
 b0=X\y;
 res0=y-X*b0;
 radj0=res0.*invsqrt_h;
 sorted0=sort(abs(radj0));
 m0=median(sorted0(2:end))/0.6745;
 assert(m0>0 && isfinite(m0));
 u0=radj0./(m0*4.685);
 CINGULUM_R2026B_IRLS_NUMERIC_CAPTURE={};
 [cb,ct]=robustfit(x,y,@capture_original_bisquare_numeric,4.685);
 C=CINGULUM_R2026B_IRLS_NUMERIC_CAPTURE;
 assert(numel(C)>=3 && numel(C)<50);
 assert(isequal(num2hex(b),num2hex(cb)));
 assert(strcmp(num2hex(st.robust_s),num2hex(ct.robust_s)));
 assert(all(isfinite([b(:);cb(:);st.robust_s;ct.robust_s])));
 rec=struct;
 rec.id=q.id;rec.n=n;rec.iterations=numel(C);
 rec.original_vs_custom_beta_exact=all(strcmp(cellstr(num2hex(b)),cellstr(num2hex(cb))));
 rec.original_vs_custom_robust_s_exact=strcmp(num2hex(st.robust_s),num2hex(ct.robust_s));
 rec.first_initial_OLS_u_exact_elements=sum(strcmp(cellstr(num2hex(u0)),cellstr(num2hex(C{1}.u))));
 rec.final_last_callback_w_vs_custom_stats_w_exact=sum(strcmp(cellstr(num2hex(C{end}.w)),cellstr(num2hex(ct.w))));
 rec.final_last_callback_w_vs_original_stats_w_exact=sum(strcmp(cellstr(num2hex(C{end}.w)),cellstr(num2hex(st.w))));
 rec.original_vs_custom_final_stats_w_exact=sum(strcmp(cellstr(num2hex(st.w)),cellstr(num2hex(ct.w))));
 rec.first_initial_mad_hex=num2hex(m0);
 rec.first_source_callback_u_hex=cellstr(num2hex(C{1}.u))';
 rec.initial_OLS_beta_hex=cellstr(num2hex(b0))';
 rec.initial_OLS_u_reconstructed_hex=cellstr(num2hex(u0))';
 rec.source_original_beta_hex=cellstr(num2hex(b))';
 rec.custom_beta_hex=cellstr(num2hex(cb))';
 rec.source_last_callback_w_hex=cellstr(num2hex(C{end}.w))';
 rec.source_original_stats_w_hex=cellstr(num2hex(st.w))';
 rec.source_mad_hex=num2hex(st.mad_s);
 rec.all_iteration_source_callbacks=cell(1,numel(C));
 rec.independent_recurrence=cell(1,numel(C)-1);
 rec.full_recurrence_next_u_exact_elements=0;
 rec.full_recurrence_next_u_total_elements=0;
 for t=1:numel(C)
  ci=C{t};
  rec.all_iteration_source_callbacks{t}=struct(...
    'iteration',t,...
    'u_hex',{cellstr(num2hex(ci.u))'},...
    'weight_hex',{cellstr(num2hex(ci.w))'});
  if t<numel(C)
   % Independently solve the next coefficient update from observed u and
   % corresponding independently authored bisquare weights.
   wi=ci.w(:);
   Xw=X.*sqrt(wi);yw=y.*sqrt(wi);
   bt=Xw\yw;
   rt=y-X*bt;
   ra=rt.*invsqrt_h;
   sorted_t=sort(abs(ra));
   mt=median(sorted_t(2:end))/0.6745;
   ut=ra./(mt*4.685);
   matches=sum(strcmp(cellstr(num2hex(ut)),cellstr(num2hex(C{t+1}.u))));
   rec.full_recurrence_next_u_exact_elements=...
     rec.full_recurrence_next_u_exact_elements+matches;
   rec.full_recurrence_next_u_total_elements=...
     rec.full_recurrence_next_u_total_elements+n;
   rec.independent_recurrence{t}=struct(...
     'iteration_after_callback',t,...
     'fit_beta_hex',{cellstr(num2hex(bt))'},...
     'computed_mad_hex',num2hex(mt),...
     'computed_next_u_hex',{cellstr(num2hex(ut))'},...
     'next_source_u_exact_elements',matches);
  end
 end
 records(end+1)=rec; %#ok<AGROW>
 CINGULUM_R2026B_IRLS_NUMERIC_CAPTURE={};
end
report=struct('status','GENUINE_R2026B_ORIGINAL_IRLS_CALLBACK_FULL_NUMERIC_RECURRENCE',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'source_original_unmodified',true,...
 'custom_callback_independently_authored',true,...
 'original_inputs_previously_disclosed',true,...
 'proprietary_implementation_not_extracted',true,...
 'original_input_sha256',m.input_sha256,'cases',numel(records),...
 'original_vs_custom_exact_beta_count',sum([records.original_vs_custom_beta_exact]),...
 'first_OLS_to_callback_u_exact',sum([records.first_initial_OLS_u_exact_elements]),...
 'last_callback_to_final_custom_w_exact',sum([records.final_last_callback_w_vs_custom_stats_w_exact]),...
 'last_callback_to_final_original_w_exact',sum([records.final_last_callback_w_vs_original_stats_w_exact]),...
 'original_to_custom_final_weights_exact',sum([records.original_vs_custom_final_stats_w_exact]),...
 'independent_recurrence_to_next_callback_u_exact',sum([records.full_recurrence_next_u_exact_elements]),...
 'independent_recurrence_to_next_callback_u_total',sum([records.full_recurrence_next_u_total_elements]),...
 'records',records);
outdir=fullfile(root,'robustfit_irls_full_recurrence_forensics_v1');
if ~exist(outdir,'dir'),mkdir(outdir);end
fd=fopen(fullfile(outdir,'genuine_source_full_irls_recurrence.json'),'w');assert(fd>0);
closefile=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
fprintf('GENUINE_MATHWORKS_ORIGINAL_IRLS_RECURR_BETA=%d/24 FIRST_U=%d/1032 RECURR_U=%d/%d\n',...
 report.original_vs_custom_exact_beta_count,report.first_OLS_to_callback_u_exact,...
 report.independent_recurrence_to_next_callback_u_exact,...
 report.independent_recurrence_to_next_callback_u_total);
end

function w=capture_original_bisquare_numeric(u)
% Independently authored public bisquare function, numerical observation only.
global CINGULUM_R2026B_IRLS_NUMERIC_CAPTURE;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_R2026B_IRLS_NUMERIC_CAPTURE{end+1}=struct('u',double(u(:)),'w',double(w(:)));
end
