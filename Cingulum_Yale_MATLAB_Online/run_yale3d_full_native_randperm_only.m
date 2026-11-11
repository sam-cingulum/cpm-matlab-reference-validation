function report = run_yale3d_full_native_randperm_only()
% Stage 1: genuine MathWorks RNG ONLY. NEVER calls Yale or fits any model.
% Publicly preregistered before synthetic inputs and Rust forecasts.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('GENUINE_MATHWORKS_REQUIRED');
end
assert(strcmp(version('-release'),'2026b'));
root = fileparts(mfilename('fullpath'));
pack = fullfile(root,'yale3d_full_pipeline_prospective');
manifest = jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(manifest.experiment_id,'yale-3d-cpm-main-full-pipeline-20261111-v1'));
assert(strcmp(manifest.source_revision,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.mathworks_release,'R2026b'));
assert(manifest.synthetic_only && manifest.original_source_not_executed && ~manifest.patient_data);
names = fieldnames(manifest.cases);
assert(numel(names)==8);
out = fullfile(root,'yale3d_full_native_results');
if ~exist(out,'dir'),mkdir(out);end
inputKey = matlab.lang.makeValidName('input.json');
summary = struct('case_name',{},'n',{},'seed',{},'k',{});
for ci=1:numel(names)
    name = names{ci};
    spec = manifest.cases.(name);
    inp = jsondecode(fileread(fullfile(pack,name,'input.json')));
    assert(strcmp(inp.name,name));
    assert(inp.n==spec.n && inp.k==spec.k && inp.seed==spec.seed);
    assert(isfield(spec.sha256,inputKey));
    rng(double(inp.seed));
    perm = double(randperm(double(inp.n)));
    assert(isequal(sort(perm),1:inp.n));
    payload = struct('runtime','MathWorks MATLAB','release',version('-release'),...
        'source_revision',manifest.source_revision,'case_name',name,...
        'input_sha256',spec.sha256.(inputKey),...
        'n',double(inp.n),'k',double(inp.k),'seed',double(inp.seed),...
        'randperm_one_based',perm(:)',...
        'source_not_run',true,'model_fit_not_run',true,...
        'patient_data',false,'arch',computer('arch'));
    preserve(fullfile(out,[name '.json']),payload);
    summary(end+1) = struct('case_name',name,'n',double(inp.n),... %#ok<AGROW>
        'seed',double(inp.seed),'k',double(inp.k));
    fprintf('YALE3D_NATIVE_PERMUTATION_ONLY %s n=%d k=%d\n',name,inp.n,inp.k);
end
report = struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'source_revision',manifest.source_revision,'source_not_run',true,...
    'model_fit_not_run',true,'cases',summary);
preserve(fullfile(out,'summary.json'),report);
end

function preserve(path,obj)
f = fopen(path,'w'); assert(f>0);
guard = onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'%s\n',jsonencode(obj));
end
