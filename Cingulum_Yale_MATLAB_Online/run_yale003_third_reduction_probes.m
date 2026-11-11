function report = run_yale003_third_reduction_probes()
% Prospective YALE-003 original-source numerical and separate binary64 gates.
% This runner is committed BEFORE fixture generation or authentic MATLAB.
% Original pinned source called unchanged. Failed cases are archived, never
% retrospectively "corrected" or silently relaxed.
if exist('OCTAVE_VERSION','builtin') ~= 0, error('GENUINE_MATHWORKS_REQUIRED'); end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
inputs=fullfile(root,'yale003_third_prospective');
manifest=jsondecode(fileread(fullfile(inputs,'manifest.json')));
assert(strcmp(manifest.experiment_id,'yale003-reductions-third-20261111-v1'));
assert(strcmp(manifest.pinned_source,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.matlab_release,'R2026b'));
assert(manifest.strict_tolerance_absolute==1e-10);
assert(manifest.separate_bitwise_equality_gate && ~manifest.patient_data);
assert(manifest.source_runner_precommitted);
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
assert(~isempty(which('computeLambdaMax')));
outdir=fullfile(root,'yale003_third_results');
if ~exist(outdir,'dir'),mkdir(outdir);end
names=fieldnames(manifest.cases);
assert(numel(names)==28);
entries=struct('case_name',{},'pass_strict',{},'pass_bitwise',{},...
    'within_weight_contract',{},'abs_lambda_error',{},'abs_mse_error',{});
allStrict=true; allBitwise=true; allRecon=true;
digestKey=matlab.lang.makeValidName('input.json');
for k=1:numel(names)
    name=names{k}; meta=manifest.cases.(name);
    assert(isfield(meta.sha256,digestKey));
    input=jsondecode(fileread(fullfile(inputs,name,'input.json')));
    frozen=jsondecode(fileread(fullfile(inputs,name,'rust.json')));
    X=double(input.x);Y=double(input.y(:));w=double(input.weights(:));
    alpha=double(input.alpha);st=logical(input.standardize);
    assert(size(X,1)==numel(Y) && numel(w)==numel(Y));
    assert(size(X,2)==3 && numel(Y)==meta.n);
    assert(all(isfinite(X),'all') && all(isfinite(Y)) && all(isfinite(w)));
    assert(all(w>=0) && any(w>0) && alpha>0 && alpha<=1);
    contract=abs(sum(w)-1)<1e-12;
    assert(contract == logical(meta.in_weight_contract));
    % The original Yale function is executed directly and unchanged.
    [lambda, mse]=computeLambdaMax(X,Y,w,alpha,st);
    % Source statement reconstruction uses genuine MATLAB kernels and
    % is cross-checked BITWISE with the original function output.
    nw=w/sum(w);
    muX=nw'*X;
    X0=bsxfun(@minus,X,muX);
    if st
        sigmaX=sqrt(nw'*(X0.^2));
        sigmaX(range(X)==0)=1;
        X0=bsxfun(@rdivide,X0,sigmaX);
    else
        sigmaX=ones(1,size(X,2));
    end
    wX0=bsxfun(@times,X0,w);
    muY=w'*Y;
    Y0=Y-muY;
    featureDot=abs(sum(bsxfun(@times,wX0,Y0)));
    reconstructedLambda=max(featureDot)/alpha;
    reconstructedMSE=w'*(Y0.^2);
    reconstructed=strcmp(num2hex(lambda),num2hex(reconstructedLambda)) && ...
        strcmp(num2hex(mse),num2hex(reconstructedMSE));
    allRecon=allRecon && reconstructed;
    rustLambda=double(frozen.lambda_max);rustMSE=double(frozen.null_mse);
    errLambda=abs(lambda-rustLambda);errMSE=abs(mse-rustMSE);
    strict=isfinite(lambda)&&isfinite(mse)&& ...
        errLambda<=1e-10 && errMSE<=1e-10;
    bitwise=strcmp(num2hex(lambda),num2hex(rustLambda)) && ...
        strcmp(num2hex(mse),num2hex(rustMSE));
    allStrict=allStrict && strict;allBitwise=allBitwise && bitwise;
    record=struct(...
        'runtime','MathWorks MATLAB','release',version('-release'),...
        'pinned_source',manifest.pinned_source,'case_name',name,...
        'fixture_sha256',meta.sha256.(digestKey),...
        'in_weight_contract',contract,'source_lambda',lambda,...
        'source_mse',mse,'source_lambda_hex',num2hex(lambda),...
        'source_mse_hex',num2hex(mse),...
        'reconstruction_hex_match',reconstructed,...
        'reconstructed_lambda_hex',num2hex(reconstructedLambda),...
        'reconstructed_mse_hex',num2hex(reconstructedMSE),...
        'mu_y_hex',num2hex(muY),...
        'mu_y_sum_hex',num2hex(sum(w.*Y)),...
        'mu_y_dot_hex',num2hex(dot(w,Y)),...
        'mu_x_hex',{cellstr(num2hex(muX(:)))},...
        'sigma_x_hex',{cellstr(num2hex(sigmaX(:)))},...
        'feature_dot_hex',{cellstr(num2hex(featureDot(:)))},...
        'mse_elementwise_sum_hex',num2hex(sum(w.*(Y0.^2))),...
        'strict_pass',strict,'bitwise_pass',bitwise,...
        'arch',computer('arch'),'maxNumCompThreads',maxNumCompThreads);
    save_json(fullfile(outdir,[name '.json']),record);
    entries(end+1)=struct('case_name',name,'pass_strict',strict,... %#ok<AGROW>
        'pass_bitwise',bitwise,'within_weight_contract',contract,...
        'abs_lambda_error',errLambda,'abs_mse_error',errMSE);
    fprintf('YALE003_THIRD %s strict=%d bitwise=%d reconstruct=%d\n', ...
        name,strict,bitwise,reconstructed);
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'experiment_id',manifest.experiment_id,'pinned_source',manifest.pinned_source,...
    'original_source_reconstruction_all_exact',allRecon,...
    'all_strict',allStrict,'all_bitwise',allBitwise,'cases',entries);
save_json(fullfile(outdir,'summary.json'),report);
if ~allRecon,error('YALE003_THIRD_SOURCE_RECONSTRUCTION_MISMATCH_OUTPUT_ARCHIVED');end
if ~allStrict,error('YALE003_THIRD_STRICT_ORIGINAL_SOURCE_GATE_FAILED_OUTPUT_ARCHIVED');end
end

function save_json(path,value)
f=fopen(path,'w');assert(f>0);c=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(value));
end
