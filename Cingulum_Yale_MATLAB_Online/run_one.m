function report = run_one(scenario)
% Independent Cingulum 6-profile Yale original-source numerical acceptance.
% Run this file under *genuine MathWorks MATLAB Online (basic or licensed)*.
% The pack contains synthetic 8-parcel data ONLY. No patient information.
% Each call uses one scenario to stay within Basic's 15-minute compute cap.
%
% Examples:
%   run_one('baseline')
%   run_one('severe_outlier')
%   run_one('47_subjects')
%
% On PASS this produces MATLAB_RESULTS_<scenario>.zip for upload back into
% the independently implemented Rust-side report verifier.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('MATLAB_ONLY: This gate must execute in genuine MathWorks MATLAB, not Octave.');
end
if nargin ~= 1 || ~ischar(scenario)
    error('Enter a named synthetic parity scenario as a character vector.');
end
valid = {'baseline','clean','severe_outlier','rescaled','reversed','47_subjects'};
if ~any(strcmp(scenario,valid))
    error('Unknown scenario: only the six pinned synthetic fixtures are accepted.');
end
root = fileparts(mfilename('fullpath'));
inputDir = fullfile(root,'fixtures',scenario);
resultDir = fullfile(root,'results',scenario);
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
addpath(fullfile(root,'upstream','yale-ohbm'));
required = {'robustfit','lasso','pca','partialcorr'};
for j = 1:numel(required)
    if isempty(which(required{j}))
        error('MISSING_TOOLBOX: MathWorks Statistics and Machine Learning Toolbox function %s is not available.',required{j});
    end
end
load(fullfile(inputDir,'cohort.mat'),'all_mats','all_behav');
load(fullfile(inputDir,'covariates.mat'),'all_covar');
load(fullfile(inputDir,'pca-targets.mat'),'multi_behav');
N = size(all_mats,3);
assert(N==size(all_behav,1) && N==size(all_covar,1) && N==size(multi_behav,1));
assert(size(all_mats,1)==8 && size(all_mats,2)==8);
fold_indices = (1:N)';
ref_profiles = {'main','ohbm','partial-pearson','partial-spearman','ridge-compat','pca'};
reference_commit.main = 'b903f83b476b745417b1f062f6777f5ffe118f1a';
reference_commit.ohbm = '708999b8bb27ae69722775c323da9f14ef6732c7';
toolbox = ver('stats');
if isempty(toolbox); error('MATLAB_ONLY: Statistics toolbox metadata unavailable');end
release = version('-release');
runtime_version = version;
all_ok = true;
entries = struct('profile',{},'status',{},'subjects',{},'max_abs_prediction_error',{},'tolerance',{},'max_abs_pca_target_error',{},'max_abs_pca_loading_error',{});
for i = 1:numel(ref_profiles)
    profile = ref_profiles{i};
    fprintf('Running real MATLAB original-source %s / %s...\n',scenario,profile);
    evidence = struct();
    evidence.runtime = 'MathWorks MATLAB';
    evidence.release = release;
    evidence.runtime_version = runtime_version;
    evidence.toolbox_version = toolbox.Version;
    evidence.profile = profile;
    evidence.scenario = scenario;
    evidence.subjects = N;
    evidence.data_type = 'synthetic_only';
    evidence.reference_sha_yale = reference_commit.main;
    evidence.reference_sha_ohbm = reference_commit.ohbm;
    evidence.alpha = [];
    evidence.lambda = [];
    if strcmp(profile,'main')
        [pred,perf] = cpm_main(all_mats,all_behav,'pthresh',0.05,'kfolds',N);
        evidence.pearson_r = perf(1);
    elseif strcmp(profile,'ohbm')
        [r,~,~,~,pred] = kfold_cpm_withmatrix(all_mats,all_behav,N,1,0.05,'Pearson');
        evidence.pearson_r = r(1);
    elseif strcmp(profile,'partial-pearson') || strcmp(profile,'partial-spearman')
        if strcmp(profile,'partial-pearson')
            association = 'Pearson';
        else
            association = 'Spearman';
        end
        [r,~,~,~,pred] = kfold_cpm_partial_withmatrix(all_mats,all_behav,all_covar,N,1,0.05,association);
        evidence.pearson_r = r(1);
    elseif strcmp(profile,'ridge-compat')
        [~,~,r,~,pred,coefs,intercepts,lambda_used] = ridgeCPM(all_mats,all_behav,0.05,1e-9,0.1,fold_indices,665);
        evidence.pearson_r = r;
        evidence.alpha = 1e-9;
        evidence.lambda = 0.1;
        evidence.beta_total = coefs;
        evidence.intercept_total = intercepts;
        evidence.lambda_per_fold = lambda_used;
    elseif strcmp(profile,'pca')
        [~,~,r,~,pred,new_behav,pca_coeff,coefs,intercepts,lambda_used] = ridgeCPM_PCA(all_mats,multi_behav,0.05,1e-6,0.1,fold_indices,665);
        evidence.pearson_r = r;
        evidence.alpha = 1e-6;
        evidence.lambda = 0.1;
        evidence.observed_fold_components = new_behav(:)';
        evidence.pca_loadings = pca_coeff;
        evidence.beta_total = coefs;
        evidence.intercept_total = intercepts;
        evidence.lambda_per_fold = lambda_used;
    end
    evidence.predictions = pred(:)';
    expected = jsondecode(fileread(fullfile(inputDir,['rust-',profile,'.json'])));
    predicted = double(expected.predictions(:));
    actual = double(evidence.predictions(:));
    if numel(actual)~=numel(predicted) || any(~isfinite(actual)) || any(~isfinite(predicted))
        error('Invalid held-out prediction count or nonfinite result for %s',profile);
    end
    diff = max(abs(actual-predicted));
    tol = 1e-9;
    if any(strcmp(profile,{'main','ridge-compat','pca'}))
        tol = 1e-6;
    end
    pca_target_diff = 0;
    pca_loading_diff = 0;
    if strcmp(profile,'pca')
        matlab_target = double(evidence.observed_fold_components(:));
        rust_target = double(expected.observed_fold_components(:));
        pca_target_diff = max(abs(matlab_target-rust_target));
        if size(evidence.pca_loadings,1)~=N
            error('PCA loadings have wrong row count');
        end
        for j=1:N
            target_row = double(expected.folds(j).loading(:));
            original_row = double(evidence.pca_loadings(j,:));
            pca_loading_diff = max(pca_loading_diff,max(abs(original_row(:)-target_row)));
        end
    end
    passed = isfinite(diff)&&diff<=tol&&pca_target_diff<=tol&&pca_loading_diff<=tol;
    evidence.max_abs_prediction_error = diff;
    evidence.prediction_tolerance = tol;
    evidence.passed_rust_comparison = passed;
    entry = struct('profile',profile,'status','PASS','subjects',N,...
        'max_abs_prediction_error',diff,'tolerance',tol,...
        'max_abs_pca_target_error',pca_target_diff,'max_abs_pca_loading_error',pca_loading_diff);
    if ~passed
        entry.status = 'FAIL';
        all_ok = false;
    end
    entries(end+1) = entry; %#ok<AGROW>
    file = fullfile(resultDir,['matlab-',profile,'.json']);
    fid = fopen(file,'w');
    if fid<0; error('Unable to open MATLAB evidence file');end
    fprintf(fid,'%s\n',jsonencode(evidence)); fclose(fid);
    fprintf('  %s max prediction discrepancy %.17g (tolerance %.3g)\n',entry.status,diff,tol);
end
report = struct();
report.runtime = 'MathWorks MATLAB';
report.release = release;
report.runtime_version = runtime_version;
report.toolbox_version = toolbox.Version;
report.scenario = scenario;
report.subjects = N;
report.data_type = 'synthetic_only';
report.models = entries;
report.pass = all_ok;
report.result = 'FAIL';
if all_ok; report.result = 'PASS';end
fid = fopen(fullfile(resultDir,'report.json'),'w');
if fid<0;error('Unable to persist MATLAB acceptance report');end
fprintf(fid,'%s\n',jsonencode(report));fclose(fid);
bundle = fullfile(root,['MATLAB_RESULTS_',scenario,'.zip']);
if exist(bundle,'file');delete(bundle);end
zip(bundle,fullfile(resultDir,'*.json'),root);
fprintf('\nMathWorks MATLAB %s (Statistics Toolbox %s): %s on %s\n',release,toolbox.Version,report.result,scenario);
fprintf('Download the archive: MATLAB_RESULTS_%s.zip\n',scenario);
if ~all_ok
    error('MATLAB_PARITY_FAIL: original Yale source disagrees with Rust on at least one method. Archive preserved.');
end
end
