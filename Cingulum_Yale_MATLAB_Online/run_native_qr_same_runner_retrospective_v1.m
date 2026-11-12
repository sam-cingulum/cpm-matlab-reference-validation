function report=run_native_qr_same_runner_retrospective_v1()
% Retrospective only on 48 already disclosed cases. Standalone Rust probe
% separately ran on raw x before calling this function. Its output is NEVER
% supplied to robustfit/qr. Both execute on same GitHub-hosted CPU.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'robustfit_raw_full_source_unseen_v1');
p=fullfile(root,'native_qr_retro_same_runner_v1');
data=jsondecode(fileread(fullfile(base,'input.json')));
assert(numel(data.cases)==48);
records=cell(48,1);
for k=1:48
 c=data.cases(k);x=double(c.x(:));y=double(c.y(:));n=numel(x);
 X=[ones(n,1),x];
 [~,st]=robustfit(x,y);
 [~,Rp,pivot]=qr(X,'econ','vector');
 R=Rp;
 if isequal(double(pivot(:)'),[2 1])
  R=Rp([2 1],[2 1]);
 end
 actual_R=cellstr(num2hex(st.R(:)));
 public_QR=cellstr(num2hex(R(:)));
 records{k}=struct('id',c.id,'n',n,'x_hex',{cellstr(num2hex(x(:)))'},...
    'source_R_hex',{actual_R'},'qr_api_R_hex',{public_QR'},...
    'pivot',double(pivot(:)'),...
    'original_equals_MATLAB_QR_all_bits',isequal(actual_R,public_QR));
end
[~,cpu]=system('grep -m 1 "model name" /proc/cpuinfo');
report=struct('experiment','retrospective_native_qr_same_runner_48_disclosed_v1',...
 'release',version('-release'),'matlab_version',version,...
 'native_executed_before_original',true,...
 'source_unseen_prospective',false,'source_original_unmodified',true,...
 'original_source_not_imported',true,'case_count',48,...
 'cpu',strtrim(cpu),'machine',computer,...
 'max_threads',maxNumCompThreads,...
 'mkl_cbwr',getenv('MKL_CBWR'),'mkl_threads_observed',getenv('MKL_NUM_THREADS'),...
 'omp_threads',getenv('OMP_NUM_THREADS'),...
 'github_sha',getenv('GITHUB_SHA'),'github_run_id',getenv('GITHUB_RUN_ID'),...
 'records',{records});
out=fullfile(p,'original_same_runner.json');
assert(~exist(out,'file'));
fid=fopen(out,'w');assert(fid>0);cl=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('ORIGINAL_MATLAB_R2026B_RAW_48_R_EXTRACTED_NO_PROPRIETARY_SOURCE\n');
fprintf('ORIGINAL_MATLAB_QR_API_ALL_BITS_EXACT %d/48\n',sum(cellfun(@(v)v.original_equals_MATLAB_QR_all_bits,records)));
end
