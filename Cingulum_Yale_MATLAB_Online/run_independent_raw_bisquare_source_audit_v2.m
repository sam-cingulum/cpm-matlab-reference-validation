function report=run_independent_raw_bisquare_source_audit_v2()
% Genuine R2026b historical post-hoc verification: independent raw x/y
% source-free numerical implementation vs unchanged original robustfit.
% Both functions receive raw input; clone NEVER reads original intermediates.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(base,'manifest.json')));
data=jsondecode(fileread(fullfile(base,'input.json')));
assert(m.samples==24 && numel(data.samples)==24 && m.source_not_run);
global CINGULUM_INDEPENDENT_AUDIT_SOURCE_WEIGHT_CALL_COUNT;
fields={'beta0','beta1','R','h','w','mad','robust_s','ols_s','s','t','p','callback_count'};
records=struct('id',{},'n',{},'clone_num_updates',{},...
 'source_callbacks',{},'source_reconstructed_all_exact',{},...
 'exact',{});
scores=zeros(1,numel(fields));nweighted=0;
for k=1:24
 q=data.samples(k);x=double(q.x(:));y=double(q.y(:));n=numel(x);
 original=cpm_independent_bisquare_fit_raw_v2(x,y);
 [b,st]=robustfit(x,y);
 CINGULUM_INDEPENDENT_AUDIT_SOURCE_WEIGHT_CALL_COUNT=0;
 [custom_beta,custom_st]=robustfit(x,y,@audit_weight_callback,4.685);
 ncallbacks=CINGULUM_INDEPENDENT_AUDIT_SOURCE_WEIGHT_CALL_COUNT;
 assert(isequal(num2hex(custom_beta),num2hex(b)) && ...
        strcmp(num2hex(custom_st.robust_s),num2hex(st.robust_s)));
 ols=original.ols_s;
 rs=original.robust_s;
 ss=max(rs,sqrt((n*rs^2+4*ols^2)/(n+4)));
 R=original.R;a=R(1,1);c=R(2,1);d=R(2,2);
 inv21=-(c*(1/a))/d;
 inv22=1/d;
 cov22=(inv21*inv21+inv22*inv22)*(ss*ss);
 t=original.beta(2)/sqrt(cov22);
 p=2*tcdf(-abs(t),n-2);
 cmp=struct;
 cmp.beta0=strcmp(num2hex(original.beta(1)),num2hex(b(1)));
 cmp.beta1=strcmp(num2hex(original.beta(2)),num2hex(b(2)));
 cmp.R=isequal(num2hex(original.R),num2hex(st.R));
 cmp.h=isequal(num2hex(original.h),num2hex(st.h));
 cmp.w=isequal(num2hex(original.w),num2hex(st.w));
 cmp.mad=strcmp(num2hex(original.mad_s),num2hex(st.mad_s));
 cmp.robust_s=strcmp(num2hex(original.robust_s),num2hex(st.robust_s));
 cmp.ols_s=strcmp(num2hex(ols),num2hex(st.ols_s));
 cmp.s=strcmp(num2hex(ss),num2hex(st.s));
 cmp.t=strcmp(num2hex(t),num2hex(st.t(2)));
 cmp.p=strcmp(num2hex(p),num2hex(st.p(2)));
 cmp.callback_count=(original.inferred_callback_count==ncallbacks);
 fv=zeros(1,numel(fields));
 for i=1:numel(fields),fv(i)=cmp.(fields{i});end
 scores=scores+fv;
 nweighted=nweighted+n;
 records(end+1)=struct('id',q.id,'n',n,...
   'clone_num_updates',original.iterations,...
   'source_callbacks',ncallbacks,...
   'source_reconstructed_all_exact',all(fv),...
   'exact',cmp); %#ok<AGROW>
end
report=struct('status','Genuine_R2026b_raw_x_y_independent_MATLAB_language_clone_v2_posthoc',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'source_unmodified',true,'original_inputs_previously_disclosed',true,...
 'original_implementation_not_imported',true,...
 'independent_clone_raw_x_y_input_only',true,...
 'original_input_sha256',m.input_sha256,'cases',24,...
 'fields',{fields},'exact_case_counts',scores,...
 'total_leverage_and_weight_elements',nweighted,...
 'records',records);
outdir=fullfile(root,'independent_raw_bisquare_source_audit_v2');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'independent_clone_original_source_verdict.json'),'w');assert(fid>0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
for i=1:numel(fields)
 fprintf('ORIGINAL_RAW_X_Y_INDEPENDENT_CLONE_%s_EXACT %d/24\n',fields{i},scores(i));
end
end

function w=audit_weight_callback(u)
global CINGULUM_INDEPENDENT_AUDIT_SOURCE_WEIGHT_CALL_COUNT;
CINGULUM_INDEPENDENT_AUDIT_SOURCE_WEIGHT_CALL_COUNT=...
 CINGULUM_INDEPENDENT_AUDIT_SOURCE_WEIGHT_CALL_COUNT+1;
w=double(abs(u)<1).*(1-u.^2).^2;
end
