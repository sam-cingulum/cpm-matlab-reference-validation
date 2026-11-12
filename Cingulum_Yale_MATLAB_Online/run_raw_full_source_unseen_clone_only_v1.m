function report=run_raw_full_source_unseen_clone_only_v1()
% Stage A: source-unseen independent predictions; do NOT invoke robustfit.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
root=fileparts(mfilename('fullpath'));
folder=fullfile(root,'robustfit_raw_full_source_unseen_v1');
data=jsondecode(fileread(fullfile(folder,'input.json')));
m=jsondecode(fileread(fullfile(folder,'manifest.json')));
assert(m.expected_case_count==48 && numel(data.cases)==48);
assert(strcmp(m.experiment_id,data.experiment_id));
assert(~exist(fullfile(folder,'forecast.json'),'file'));
records=cell(48,1);
for k=1:48
 q=data.cases(k);x=double(q.x(:));y=double(q.y(:));n=numel(x);
 assert(numel(y)==n && n==q.n);
 c=cpm_independent_bisquare_fit_raw_v2(x,y);
 ols=c.ols_s;rs=c.robust_s;
 s=max(rs,sqrt((n*rs^2+4*ols^2)/(n+4)));
 R=c.R;a=R(1,1);cc=R(2,1);d=R(2,2);
 inv21=-(cc*(1/a))/d;
 inv22=1/d;
 cov22=(inv21*inv21+inv22*inv22)*(s*s);
 t=c.beta(2)/sqrt(cov22);
 p=2*tcdf(-abs(t),n-2);
 rec=struct;rec.id=q.id;rec.n=n;rec.fields=struct;
 rec.fields.intercept=hexvec(c.beta(1));
 rec.fields.slope=hexvec(c.beta(2));
 rec.fields.R=hexvec(c.R);
 rec.fields.h=hexvec(c.h);
 rec.fields.w=hexvec(c.w);
 rec.fields.mad_s=hexvec(c.mad_s);
 rec.fields.robust_s=hexvec(c.robust_s);
 rec.fields.ols_s=hexvec(ols);
 rec.fields.s=hexvec(s);
 rec.fields.t=hexvec(t);
 rec.fields.p=hexvec(p);
 rec.fields.callbacks=hexvec(double(c.inferred_callback_count));
 records{k}=rec;
end
report=struct('experiment_id',m.experiment_id,'stage','A_independent_clone_only',...
 'release',version('-release'),'source_never_invoked',true,...
 'predictor','cpm_independent_bisquare_fit_raw_v2',...
 'input_sha256',m.input_sha256,'records',{records},'profile',runtime_profile_v1());
out=fullfile(folder,'forecast.json');
fid=fopen(out,'w');assert(fid>0);cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('STAGE_A_INDEPENDENT_CLONE_48_PREDICTIONS_NO_ORIGINAL_SOURCE\n');
end
function v=hexvec(x)
v=cellstr(num2hex(x(:)));
end
function p=runtime_profile_v1()
[~,cpu]=system('grep -m 1 "model name" /proc/cpuinfo');
p=struct('matlab_version',version,'release',version('-release'),...
 'architecture',computer,'cpu_model',strtrim(cpu),...
 'max_num_comp_threads',maxNumCompThreads,...
 'mkl_cbwr',getenv('MKL_CBWR'),'mkl_num_threads',getenv('MKL_NUM_THREADS'),...
 'omp_num_threads',getenv('OMP_NUM_THREADS'),...
 'github_sha',getenv('GITHUB_SHA'),'github_run_id',getenv('GITHUB_RUN_ID'),...
 'github_run_attempt',getenv('GITHUB_RUN_ATTEMPT'));
end
