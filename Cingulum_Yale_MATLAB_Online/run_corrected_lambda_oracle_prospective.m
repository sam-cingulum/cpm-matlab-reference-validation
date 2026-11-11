function report = run_corrected_lambda_oracle_prospective()
% INDEPENDENT MATLAB mathematical oracle, NOT unchanged Yale source.
% PREREGISTER BEFORE freezing unseen synthetic input/Rust forecasts.
% Uses PAIRWISE covariance and variance identities, not the Rust algorithm's
% anchor/centred-difference accumulation. No requirement for Yale source.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('GENUINE_MATHWORKS_REQUIRED');
end
assert(strcmp(version('-release'), '2026b'));
root = fileparts(mfilename('fullpath'));
fixtureDir = fullfile(root, 'corrected_lambda_prospective');
manifest = jsondecode(fileread(fullfile(fixtureDir, 'manifest.json')));
assert(strcmp(manifest.experiment_id, 'corrected-weighted-lambda-20261111-v1'));
assert(strcmp(manifest.mathworks_release, 'R2026b'));
assert(strcmp(manifest.tolerance_abs, '5E-12'));
assert(strcmp(manifest.tolerance_rel, '5E-11'));
assert(~manifest.patient_data && manifest.precommitted_protocol);
names = fieldnames(manifest.cases);
assert(numel(names) == 32);
resultDir = fullfile(root, 'corrected_lambda_oracle_results');
if ~exist(resultDir, 'dir'), mkdir(resultDir); end
tolAbs = 5e-12;
tolRel = 5e-11;
entries = struct('case_name', {}, 'pass_rust', {}, 'pass_decimal', {}, ...
    'lambda_abs_delta_rust', {}, 'mse_abs_delta_rust', {});
allPassed = true;
for k = 1:numel(names)
    name = names{k};
    folder = fullfile(fixtureDir, name);
    inp = jsondecode(fileread(fullfile(folder,'input.json')));
    rust = jsondecode(fileread(fullfile(folder,'rust.json')));
    high = jsondecode(fileread(fullfile(folder,'decimal.json')));
    X = double(inp.x); y = double(inp.y(:));
    if isempty(inp.weights)
        w = ones(numel(y), 1);
    else
        w = double(inp.weights(:));
    end
    assert(numel(y) == size(X,1) && numel(w) == numel(y));
    assert(all(isfinite(X), 'all') && all(isfinite(y)) && all(isfinite(w)));
    assert(all(w >= 0) && any(w > 0));
    assert(inp.alpha > 0 && inp.alpha <= 1);
    % Unlike the implementation under test, use the identity
    % cov_p(x,y) = 1/2 sum_{ik} p_i p_k (x_i-x_k)(y_i-y_k).
    % This avoids fitting to a particular mean/reduction order and
    % independently derives the unpenalized intercept's null MSE.
    p = w / sum(w);
    outer = p * p.';
    dy = y - y.';
    nullMSE = 0.5 * sum(outer .* (dy.^2), 'all');
    scores = zeros(1,size(X,2));
    for j = 1:size(X,2)
        dx = X(:,j) - X(:,j).';
        covariance = 0.5 * sum(outer .* dx .* dy, 'all');
        if logical(inp.standardize)
            variance = 0.5 * sum(outer .* (dx.^2), 'all');
            if variance == 0
                covariance = 0;
            else
                covariance = covariance / sqrt(variance);
            end
        end
        scores(j) = covariance;
    end
    lambdaMax = max(abs(scores)) / inp.alpha;
    decimalLambda = str2double(high.lambda_max);
    decimalMSE = str2double(high.null_mse);
    absRustLambda = abs(lambdaMax - double(rust.lambda_max));
    absRustMSE = abs(nullMSE - double(rust.null_mse));
    passRust = isfinite(lambdaMax) && isfinite(nullMSE) && ...
        absRustLambda <= tolAbs + tolRel * abs(double(rust.lambda_max)) && ...
        absRustMSE <= tolAbs + tolRel * abs(double(rust.null_mse));
    passDecimal = abs(lambdaMax - decimalLambda) <= tolAbs + tolRel*abs(decimalLambda) && ...
        abs(nullMSE - decimalMSE) <= tolAbs + tolRel*abs(decimalMSE);
    allPassed = allPassed && passRust && passDecimal;
    artifact = struct('runtime','MathWorks MATLAB', 'release','R2026b', ...
        'case_name',name, 'fixture_sha256',manifest.cases.(name).sha256.('input.json'), ...
        'oracle_algorithm','pairwise_weighted_covariance_identity', ...
        'lambda_max',lambdaMax, 'null_mse',nullMSE, ...
        'lambda_hex',num2hex(lambdaMax),'mse_hex',num2hex(nullMSE), ...
        'pass_rust',passRust, 'pass_decimal',passDecimal);
    persist(fullfile(resultDir,[name '.json']),artifact);
    entries(end+1) = struct('case_name',name,'pass_rust',passRust, ... %#ok<AGROW>
        'pass_decimal',passDecimal,'lambda_abs_delta_rust',absRustLambda, ...
        'mse_abs_delta_rust',absRustMSE);
    fprintf('CORRECTED_LAMBDA %s rust=%d decimal=%d\n',name,passRust,passDecimal);
end
report = struct('runtime','MathWorks MATLAB','release','R2026b', ...
    'experiment_id',manifest.experiment_id,'all_pass',allPassed,'cases',entries);
persist(fullfile(resultDir,'summary.json'),report);
if ~allPassed
    error('CORRECTED_LAMBDA_MATHEMATICAL_PROSPECTIVE_GATE_FAILED_OUTPUT_ARCHIVED');
end
end

function persist(path, value)
fid=fopen(path,'w');
assert(fid>0);
closer=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(value));
end
