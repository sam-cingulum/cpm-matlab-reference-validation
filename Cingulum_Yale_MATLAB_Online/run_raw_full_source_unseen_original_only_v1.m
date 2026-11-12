function report=run_raw_full_source_unseen_original_only_v1()
% Stage B: invoke genuine original unchanged MathWorks robustfit ONLY.
% Stage A exact-hex predictions must have been sealed in a prior public commit.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
root=fileparts(mfilename('fullpath'));
folder=fullfile(root,'robustfit_raw_full_source_unseen_v1');
data=jsondecode(fileread(fullfile(folder,'input.json')));
m=jsondecode(fileread(fullfile(folder,'manifest.json')));
assert(m.expected_case_count==48 && numel(data.cases)==48);
assert(exist(fullfile(folder,'forecast.json'),'file')==2);
assert(exist(fullfile(folder,'forecast_seal.json'),'file')==2);
assert(~exist(fullfile(folder,'source_result.json'),'file'));
global CINGULUM_RAW_FULL_SOURCE_UNSEEN_CALLBACKS;
records=cell(48,1);
for k=1:48
 q=data.cases(k);x=double(q.x(:));y=double(q.y(:));n=numel(x);
 assert(numel(y)==n && n==q.n);
 [beta,st]=robustfit(x,y);
 CINGULUM_RAW_FULL_SOURCE_UNSEEN_CALLBACKS=0;
 [beta_cb,st_cb]=robustfit(x,y,@source_bisquare_counter,4.685);
 callbacks=CINGULUM_RAW_FULL_SOURCE_UNSEEN_CALLBACKS;
 assert(isequal(num2hex(beta),num2hex(beta_cb)));
 assert(isequal(num2hex(st.robust_s),num2hex(st_cb.robust_s)));
 rec=struct;rec.id=q.id;rec.n=n;rec.fields=struct;
 rec.fields.intercept=hexvec(beta(1));
 rec.fields.slope=hexvec(beta(2));
 rec.fields.R=hexvec(st.R);
 rec.fields.h=hexvec(st.h);
 rec.fields.w=hexvec(st.w);
 rec.fields.mad_s=hexvec(st.mad_s);
 rec.fields.robust_s=hexvec(st.robust_s);
 rec.fields.ols_s=hexvec(st.ols_s);
 rec.fields.s=hexvec(st.s);
 rec.fields.t=hexvec(st.t(2));
 rec.fields.p=hexvec(st.p(2));
 rec.fields.callbacks=hexvec(double(callbacks));
 records{k}=rec;
end
report=struct('experiment_id',m.experiment_id,'stage','B_original_unchanged_robustfit_only',...
 'release',version('-release'),'genuine_original_robustfit',true,...
 'input_sha256',m.input_sha256,'records',{records},'profile',runtime_profile_v1());
out=fullfile(folder,'source_result.json');
fid=fopen(out,'w');assert(fid>0);cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('STAGE_B_UNCHANGED_ORIGINAL_ROBUSTFIT_48_CASES\n');
end
function w=source_bisquare_counter(u)
global CINGULUM_RAW_FULL_SOURCE_UNSEEN_CALLBACKS;
CINGULUM_RAW_FULL_SOURCE_UNSEEN_CALLBACKS=...
 CINGULUM_RAW_FULL_SOURCE_UNSEEN_CALLBACKS+1;
w=double(abs(u)<1).*(1-u.^2).^2;
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
