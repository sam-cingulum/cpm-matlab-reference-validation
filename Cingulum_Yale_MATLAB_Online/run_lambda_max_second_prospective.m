function report = run_lambda_max_second_prospective()
% Execute unchanged pinned Yale computeLambdaMax under genuine MATLAB R2026b.
% This runner and its acceptance threshold are committed before new inputs.
if exist('OCTAVE_VERSION','builtin')~=0, error('GENUINE_MATLAB_REQUIRED');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
fixtures=fullfile(root,'lambda_max_second_prospective');
manifest=jsondecode(fileread(fullfile(fixtures,'manifest.json')));
assert(strcmp(manifest.pinned_source,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.matlab_release,'R2026b'));
assert(manifest.tolerance_absolute==1e-10);
assert(~manifest.patient_data && manifest.source_runner_precommitted && ~manifest.correction_changes_original_source);
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
assert(~isempty(which('computeLambdaMax')));
resultDir=fullfile(root,'lambda_max_second_results');
if ~exist(resultDir,'dir'),mkdir(resultDir);end
cases=fieldnames(manifest.cases);
assert(numel(cases)==16);
entries=struct('case_name',{},'pass_strict',{},'weights_pre_normalized',{}, ...
    'lambda_error',{},'mse_error',{});
all_pass=true; normalized_all_pass=true;
for ci=1:numel(cases)
    name=cases{ci};
    folder=fullfile(fixtures,name);
    input=jsondecode(fileread(fullfile(folder,'input.json')));
    frozen=jsondecode(fileread(fullfile(folder,'rust.json')));
    X=double(input.x);y=double(input.y(:));w=double(input.weights(:));
    normalized=logical(manifest.cases.(name).spec.weights_pre_normalized);
    assert(numel(y)==size(X,1) && numel(w)==numel(y));
    if normalized
        assert(abs(sum(w)-1)<1e-12);
    else
        assert(abs(sum(w)-1)>=1e-12);
    end
    [lambda,mse]=computeLambdaMax(X,y,w,input.alpha,logical(input.standardize));
    err_lambda=abs(lambda-double(frozen.lambda_max));
    err_mse=abs(mse-double(frozen.null_mse));
    passed=isfinite(lambda)&&isfinite(mse) && ...
        err_lambda<=manifest.tolerance_absolute && err_mse<=manifest.tolerance_absolute;
    all_pass=all_pass && passed;
    if normalized,normalized_all_pass=normalized_all_pass && passed;end
    entry=struct('case_name',name,'pass_strict',passed, ...
        'weights_pre_normalized',normalized,'lambda_error',err_lambda,'mse_error',err_mse);
    entries(end+1)=entry; %#ok<AGROW>
    artifact=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
        'source_commit',manifest.pinned_source,'case_name',name, ...
        'lambda_max',lambda,'null_mse',mse,'pass_strict',passed, ...
        'weights_pre_normalized',normalized);
    save_json(fullfile(resultDir,[name '.json']),artifact);
    fprintf('YALE003 %s strict=%d abs_lambda=%.17g abs_mse=%.17g\n', ...
        name,passed,err_lambda,err_mse);
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
    'source_commit',manifest.pinned_source,'cases',entries, ...
    'all_pass',all_pass,'normalized_all_pass',normalized_all_pass);
save_json(fullfile(resultDir,'summary.json'),report);
if ~all_pass
    error('YALE003_SECOND_PROSPECTIVE_STRICT_GATE_FAIL_EVIDENCE_RETAINED');
end
end
function save_json(path,body)
f=fopen(path,'w');
assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(body));
end
