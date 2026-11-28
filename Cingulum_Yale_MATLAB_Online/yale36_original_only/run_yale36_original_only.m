function run_yale36_original_only()
% Capture genuine original Yale results as binary64 words for six public
% synthetic scenarios and six unchanged original model entry points.
assert(exist('OCTAVE_VERSION','builtin') == 0, 'MathWorks MATLAB required');
assert(strcmp(version('-release'),'2026b'), 'MATLAB R2026b required');
assert(contains(version,'(R2026b) Update 1'), 'R2026b Update 1 required');
maxNumCompThreads(1);
assert(maxNumCompThreads == 1, 'A single computational thread is required');
stats = ver('stats');
assert(~isempty(stats), 'Statistics and Machine Learning Toolbox required');

root = fileparts(mfilename('fullpath'));
fixtures = fullfile(root,'..','fixtures');
upstream = fullfile(root,'upstream');
addpath(fullfile(upstream,'yale-cpm','matlab','func'));
addpath(fullfile(upstream,'yale-cpm','matlab','misc'));
addpath(fullfile(upstream,'yale-ohbm'));

required = {
    'cpm_main', fullfile(upstream,'yale-cpm','matlab','func','cpm_main.m');
    'ridgeCPM', fullfile(upstream,'yale-cpm','matlab','misc','ridgeCPM.m');
    'ridgeCPM_PCA', fullfile(upstream,'yale-cpm','matlab','misc','ridgeCPM_PCA.m');
    'kfold_cpm_withmatrix', fullfile(upstream,'yale-ohbm','kfold_cpm_withmatrix.m');
    'kfold_cpm_partial_withmatrix', fullfile(upstream,'yale-ohbm','kfold_cpm_partial_withmatrix.m')};
for j = 1:size(required,1)
    assert(strcmp(which(required{j,1}),required{j,2}), ...
        'Unexpected source for %s',required{j,1});
end
for name = {'corr','partialcorr','robustfit','lasso','pca','regress'}
    location = which(name{1});
    assert(startsWith(location,matlabroot) || contains(location,'built-in'), ...
        'Unexpected MathWorks implementation for %s',name{1});
end

scenarios = {'baseline','clean','severe_outlier','rescaled','reversed','47_subjects'};
profiles = {'main','ohbm','partial-pearson','partial-spearman','ridge-compat','pca'};
outdir = fullfile(root,'out');
if ~exist(outdir,'dir'); mkdir(outdir); end

provenance = struct();
provenance.classification = 'YALE36_ORIGINAL_ONLY_MATHWORKS_R2026B_BINARY64';
provenance.release = version('-release');
provenance.runtime_version = version;
provenance.toolbox_version = stats.Version;
provenance.blas = version('-blas');
provenance.lapack = version('-lapack');
provenance.max_computation_threads = maxNumCompThreads;
provenance.mkl_cbwr = getenv('MKL_CBWR');
provenance.run_id = getenv('GITHUB_RUN_ID');
provenance.public_commit = getenv('GITHUB_SHA');
provenance.source_yale_cpm = getenv('YALE_CPM_COMMIT');
provenance.source_yale_ohbm = getenv('YALE_OHBM_COMMIT');
provenance.seed_per_profile = 665;
provenance.scenarios = scenarios;
provenance.profiles = profiles;
provenance.expected_case_count = numel(scenarios)*numel(profiles);
write_json(fullfile(outdir,'provenance.json'),provenance);

total = 0;
for si = 1:numel(scenarios)
    scenario = scenarios{si};
    inputdir = fullfile(fixtures,scenario);
    load(fullfile(inputdir,'cohort.mat'),'all_mats','all_behav');
    load(fullfile(inputdir,'covariates.mat'),'all_covar');
    load(fullfile(inputdir,'pca-targets.mat'),'multi_behav');
    N = size(all_mats,3);
    expected_N = 48;
    if strcmp(scenario,'47_subjects'); expected_N = 47; end
    assert(N == expected_N, 'Unexpected subject count for %s',scenario);
    assert(isequal(size(all_mats,1),8) && isequal(size(all_mats,2),8));
    assert(size(all_behav,1)==N && size(all_covar,1)==N && size(multi_behav,1)==N);

    for pi = 1:numel(profiles)
        profile = profiles{pi};
        rng(665,'twister');
        primary = original_profile(profile,all_mats,all_behav,all_covar,multi_behav,N);
        rng(665,'twister');
        repeated = original_profile(profile,all_mats,all_behav,all_covar,multi_behav,N);
        assert(isequal(primary.shapes,repeated.shapes) && ...
            isequal(primary.fields,repeated.fields), ...
            'Original source repeated binary64 words differ for %s/%s',scenario,profile);

        evidence = struct();
        evidence.scenario = scenario;
        evidence.profile = profile;
        evidence.subjects = N;
        evidence.shapes = primary.shapes;
        evidence.fields = primary.fields;
        evidence.word_count = primary.word_count;
        evidence.repetitions_identical = 2;
        write_json(fullfile(outdir,sprintf('original-%s-%s.json',scenario,profile)),evidence);
        total = total + 1;
        fprintf('%d/%d original Yale %s %s: %d binary64 words, repetitions identical\n', ...
            total,provenance.expected_case_count,scenario,profile,evidence.word_count);
    end
end
assert(total == 36, 'Original 36-case run is incomplete');
provenance.completed_case_count = total;
write_json(fullfile(outdir,'provenance.json'),provenance);
end

function out = original_profile(profile,all_mats,all_behav,all_covar,multi_behav,N)
values = struct();
switch profile
    case 'main'
        [pred,perf] = cpm_main(all_mats,all_behav,'pthresh',0.05,'kfolds',N);
        values.pearson_r = perf(1);
    case 'ohbm'
        [r,~,~,~,pred] = kfold_cpm_withmatrix(all_mats,all_behav,N,1,0.05,'Pearson');
        values.pearson_r = r(1);
    case {'partial-pearson','partial-spearman'}
        association = 'Pearson';
        if strcmp(profile,'partial-spearman'); association = 'Spearman'; end
        [r,~,~,~,pred] = kfold_cpm_partial_withmatrix( ...
            all_mats,all_behav,all_covar,N,1,0.05,association);
        values.pearson_r = r(1);
    case 'ridge-compat'
        [~,~,r,~,pred] = ridgeCPM(all_mats,all_behav,0.05,1e-9,0.1,(1:N)',665);
        values.pearson_r = r;
        values.alpha = 1e-9;
        values.lambda = 0.1;
    case 'pca'
        [~,~,r,~,pred,new_behav,pca_coeff] = ridgeCPM_PCA( ...
            all_mats,multi_behav,0.05,1e-6,0.1,(1:N)',665);
        values.pearson_r = r;
        values.alpha = 1e-6;
        values.lambda = 0.1;
        values.observed_fold_components = new_behav(:)';
        values.pca_loadings = pca_coeff;
    otherwise
        error('Unknown original Yale profile %s',profile);
end
values.predictions = pred(:)';
assert(numel(values.predictions)==N, 'Unexpected prediction count');

out = struct('shapes',struct(),'fields',struct(),'word_count',0);
names = fieldnames(values);
for fi = 1:numel(names)
    name = names{fi};
    value = values.(name);
    assert(isnumeric(value) && isreal(value), 'Unexpected output type for %s',name);
    words = cellstr(num2hex(double(value(:))));
    out.shapes.(name) = size(value);
    out.fields.(name) = words(:)';
    out.word_count = out.word_count + numel(words);
end
end

function write_json(path,record)
fid = fopen(path,'w');
assert(fid > 0, 'Cannot write original-only evidence');
cleaner = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(record));
end
