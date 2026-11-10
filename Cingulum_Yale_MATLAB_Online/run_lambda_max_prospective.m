function report = run_lambda_max_prospective()
% Genuine MathWorks original Yale computeLambdaMax.m source identity.
% All synthetic Rust forecasts and SHA256s were frozen in public Git
% before running source. No patient data and no MATLAB engine substitutes.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('MATLAB_ONLY: Genuine MathWorks MATLAB required');
end
root=fileparts(mfilename('fullpath'));
fixtures=fullfile(root,'lambda_max_prospective');
manifest=jsondecode(fileread(fullfile(fixtures,'manifest.json')));
assert(~manifest.patient_data_included);
assert(strcmp(manifest.original_yale_sha,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(manifest.numeric_absolute_tolerance==1e-10);
assert(manifest.require_original_source_unchanged && manifest.require_complete_original_results);
assert(strcmp(version('-release'),'2026b'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
assert(~isempty(which('computeLambdaMax')));
resultDir=fullfile(root,'lambda_max_results');
if ~exist(resultDir,'dir'),mkdir(resultDir);end
cases=fieldnames(manifest.cases);
entries=struct('case_name',{},'pass',{},'absolute_lambda_error',{}, ...
    'absolute_null_mse_error',{},'lambda_max',{},'null_mse',{});
all_pass=true;
for ci=1:numel(cases)
    name=cases{ci};
    folder=fullfile(fixtures,name);
    input=jsondecode(fileread(fullfile(folder,'input.json')));
    original_rust=jsondecode(fileread(fullfile(folder,'rust.json')));
    X=double(input.x);
    y=double(input.y(:));
    if isempty(input.weights)
        w=[];
    else
        w=double(input.weights(:));
    end
    assert(isequal(size(X),[numel(y),manifest.cases.(name).spec.features]));
    [lam,mse]=computeLambdaMax(X,y,w,input.alpha,logical(input.standardize));
    lambda_error=abs(double(lam)-double(original_rust.lambda_max));
    mse_error=abs(double(mse)-double(original_rust.null_mse));
    passed=isfinite(lam)&&isfinite(mse)&&lambda_error<=manifest.numeric_absolute_tolerance ...
        &&mse_error<=manifest.numeric_absolute_tolerance;
    all_pass=all_pass && passed;
    entry=struct('case_name',name,'pass',passed,'absolute_lambda_error',lambda_error, ...
        'absolute_null_mse_error',mse_error,'lambda_max',double(lam),'null_mse',double(mse));
    entries(end+1)=entry; %#ok<AGROW>
    artifact=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
        'source_commit',manifest.original_yale_sha,'case_name',name, ...
        'patient_data_included',false,'lambda_max',double(lam), ...
        'null_mse',double(mse),'comparison',entry);
    write_json(fullfile(resultDir,[name '.json']),artifact);
    fprintf('LAMBDA MAX ORIGINAL YALE %s %d : lambda error %.17g, MSE error %.17g\n', ...
        name,passed,lambda_error,mse_error);
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
    'source_commit',manifest.original_yale_sha, ...
    'toolbox_version','', 'cases',entries, ...
    'case_count',numel(entries),'all_pass',all_pass);
toolbox=ver('stats');
if ~isempty(toolbox),report.toolbox_version=toolbox.Version;end
write_json(fullfile(resultDir,'summary.json'),report);
if ~all_pass
    error('ORIGINAL_YALE_COMPUTELAMBDAMAX_STRICT_PARITY_FAILED: original result evidence preserved');
end
end

function write_json(path,value)
fid=fopen(path,'w');
if fid<0,error('Failed to preserve original MATLAB evidence');end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(value));
end
