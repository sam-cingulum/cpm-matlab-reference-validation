function report=run_matlab_sum_binary64_prospective_v2()
% Unmodified genuine MathWorks R2026b sum/mean on frozen source-unseen input
% vectors. This script never opens, reads or refers to Python predictions.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
folder=fullfile(root,'sum_binary64_prospective_v2');
m=jsondecode(fileread(fullfile(folder,'manifest.json')));
data=jsondecode(fileread(fullfile(folder,'input.json')));
assert(strcmp(m.experiment_id,'r2026b-matlab-sum-binary64-predeclared-source-unseen-v2'));
assert(strcmp(data.experiment_id,m.experiment_id));
assert(m.source_not_run_at_freeze);
assert(m.hypotheses_frozen_before_genuine_source);
assert(m.expected_all_sum_and_mean_binary64_exact);
assert(m.examples_count==numel(data.examples));
T=struct('id','','n',0,'source_sum_hex','','source_mean_hex','');
records=repmat(T,1,m.examples_count);
for i=1:numel(data.examples)
 item=data.examples(i);
 v=double(item.values(:));
 assert(numel(v)==item.n && all(isfinite(v)));
 rec=T;rec.id=item.id;rec.n=item.n;
 rec.source_sum_hex=num2hex(sum(v));
 rec.source_mean_hex=num2hex(mean(v));
 records(i)=rec;
end
report=struct('status','GENUINE_SOURCE_UNMODIFIED_R2026B_SUM_MEAN_BINARY64',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'source_function_unmodified',true,'source_input_forecasts_never_read',true,...
 'experiment_id',m.experiment_id,...
 'input_sha256',m.frozen_input_sha256,...
 'forecast_pre_frozen_sha256',m.frozen_forecast_sha256,...
 'record_count',numel(records),'records',records);
outdir=fullfile(root,'sum_binary64_source_v2');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'original_matlab_sum_mean.json'),'w');assert(fid>0);
finalize=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('GENUINE_MATHWORKS_SOURCE_UNMODIFIED_SUM_MEAN_COUNT=%d\n',numel(records));
end
