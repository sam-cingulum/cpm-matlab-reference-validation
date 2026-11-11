function report = run_cpmcv_full_native_randperm_only_b64_v2()
% ONLY genuine MATLAB randperm; no original Yale source model execution.
% Preregistered before synthetic input freeze. Stage B executes actual source
% only after these permutations + Rust forecasts are publicly frozen.
if exist('OCTAVE_VERSION','builtin')~=0,error('GENUINE_MATHWORKS_REQUIRED');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'cpmcv_b64_v2');
manifest=jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(manifest.experiment_id,'yale-cpmcv-b64-parser-20261111-v2'));
assert(strcmp(manifest.source_revision,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.mathworks_release,'R2026b'));
assert(manifest.synthetic_only && manifest.original_source_not_executed);
names=fieldnames(manifest.cases);
assert(numel(names)==8);
outdir=fullfile(root,'cpmcv_b64_v2_native_results');
if ~exist(outdir,'dir'),mkdir(outdir);end
inputKey=matlab.lang.makeValidName('input.json');
summaries=struct('case_name',{},'n',{},'k',{},'seed',{});
for i=1:numel(names)
    name=names{i};spec=manifest.cases.(name);
    assert(isfield(spec.sha256,inputKey));
    inp=jsondecode(fileread(fullfile(pack,name,'input.json')));
    assert(strcmp(inp.name,name));
    n=double(inp.n);k=double(inp.k);seed=double(inp.seed);
    assert(n==spec.n && k==spec.k && seed==spec.seed);
    assert(n>k || n==k);
    rng(seed);
    % No cpm_cv, cpm_train, cpm_test, robustfit or corr is invoked.
    perm=double(randperm(n));
    assert(numel(perm)==n && isequal(sort(perm),1:n));
    record=struct('runtime','MathWorks MATLAB',...
        'release',version('-release'),...
        'source_revision',manifest.source_revision,...
        'case_name',name,'input_sha256',spec.sha256.(inputKey),...
        'n',n,'k',k,'seed',seed,'randperm_one_based',perm(:)',...
        'source_not_run',true,'model_fit_not_run',true,...
        'patient_data',false,'arch',computer('arch'));
    preserve(fullfile(outdir,[name '.json']),record);
    summaries(end+1)=struct('case_name',name,'n',n,'k',k,'seed',seed); %#ok<AGROW>
    fprintf('CPMCV_NATIVE_RANDPERM_ONLY %s n=%d k=%d\n',name,n,k);
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'source_revision',manifest.source_revision,...
    'case_count',numel(names),'source_not_run',true,...
    'model_fit_not_run',true,'cases',summaries);
preserve(fullfile(outdir,'summary.json'),report);
end

function preserve(path,obj)
f=fopen(path,'w');assert(f>0);
closeFile=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(obj));
end
