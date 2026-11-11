function report = run_yale3d_full_original_cpm_main()
% Stage 2: unchanged original Yale cpm_main.m executes ONLY AFTER:
% (i) source-invisible 3D inputs are publicly frozen, (ii) MathWorks native
% randperm-only stage, (iii) ACTUAL Rust complete forecasts publicly frozen.
% Separately reconstruct every model through unchanged cpm_train/cpm_test.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('GENUINE_MATHWORKS_REQUIRED');
end
assert(strcmp(version('-release'),'2026b'));
root = fileparts(mfilename('fullpath'));
pack = fullfile(root,'yale3d_full_pipeline_prospective');
manifest = jsondecode(fileread(fullfile(pack,'manifest.json')));
forecasts = jsondecode(fileread(fullfile(pack,'conditional_forecast_manifest.json')));
assert(strcmp(manifest.experiment_id,'yale-3d-cpm-main-full-pipeline-20261111-v1'));
assert(strcmp(forecasts.experiment_id,manifest.experiment_id));
assert(strcmp(manifest.source_revision,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(forecasts.source_revision,manifest.source_revision));
assert(strcmp(manifest.mathworks_release,'R2026b'));
assert(manifest.synthetic_only && manifest.original_source_not_executed && ~manifest.patient_data);
assert(forecasts.original_source_not_executed && forecasts.source_predictions_frozen_before_original_matlab);
assert(manifest.acceptance.source_feature_exact_binary64 && manifest.acceptance.edge_mask_exact);
assert(manifest.acceptance.fold_indices_exact && manifest.acceptance.zero_placeholder_exact);
assert(manifest.acceptance.edge_r_absolute==1e-10);
assert(manifest.acceptance.edge_p_absolute==1e-8);
assert(manifest.acceptance.summary_absolute==1e-9);
assert(manifest.acceptance.coefficient_absolute==1e-9);
assert(manifest.acceptance.prediction_absolute==1e-8);
assert(manifest.acceptance.performance_r_absolute==1e-9);
assert(manifest.acceptance.performance_p_absolute==1e-8);
assert(manifest.acceptance.source_self_reconstruction_absolute==1e-9);
names = fieldnames(manifest.cases);
assert(numel(names)==8 && numel(fieldnames(forecasts.cases))==8);
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
assert(~isempty(which('cpm_main')) && ~isempty(which('cpm_check_errors')) && ...
    ~isempty(which('cpm_cv')) && ~isempty(which('cpm_train')) && ...
    ~isempty(which('cpm_test')) && ~isempty(which('robustfit')));
out = fullfile(root,'yale3d_full_original_results');
if ~exist(out,'dir'),mkdir(out);end
inputKey = matlab.lang.makeValidName('input.json');
nativeKey = matlab.lang.makeValidName('native_randperm.json');
rustKey = matlab.lang.makeValidName('rust_source.json');
cases = struct('case_name',{},'n',{},'k',{},'original_error',{},'reconstruction_error',{});
healthy = 0;
for ci=1:numel(names)
    name = names{ci};
    spec = manifest.cases.(name);
    f = forecasts.cases.(name).sha256;
    assert(isfield(spec.sha256,inputKey) && isfield(f,nativeKey) && isfield(f,rustKey));
    inp = jsondecode(fileread(fullfile(pack,name,'input.json')));
    native = jsondecode(fileread(fullfile(pack,name,'native_randperm.json')));
    rust = jsondecode(fileread(fullfile(pack,name,'rust_source.json')));
    assert(strcmp(inp.name,name));
    assert(inp.n==spec.n && inp.k==spec.k && inp.seed==spec.seed);
    assert(strcmp(native.runtime,'MathWorks MATLAB') && strcmp(native.release,'2026b'));
    assert(native.source_not_run && native.model_fit_not_run);
    assert(strcmp(native.input_sha256,spec.sha256.(inputKey)));
    assert(strcmp(rust.policy,'yale_source_compatibility'));
    assert(numel(rust.folds)==inp.k && numel(rust.predictions)==inp.n);
    sourceData = inp.three_d.subject_matrices;
    assert(ndims(sourceData)==3 && size(sourceData,1)==inp.n);
    assert(size(sourceData,2)==inp.rows && size(sourceData,3)==inp.cols);
    X = permute(double(sourceData),[2,3,1]); % [row, col, subject]
    Y = double(inp.outcomes(:));
    n = numel(Y);k=double(inp.k);pthresh=double(inp.p_threshold);
    assert(n==inp.n && all(isfinite(X),'all') && all(isfinite(Y)));
    assert(pthresh>0 && pthresh<1);
    rng(double(inp.seed));
    nativePermutation = double(randperm(n));
    assert(isequal(nativePermutation(:),double(native.randperm_one_based(:))));
    record = struct('runtime','MathWorks MATLAB','release',version('-release'),...
        'source_revision',manifest.source_revision,...
        'case_name',name,'input_sha256',spec.sha256.(inputKey),...
        'native_sha256',f.(nativeKey),'frozen_rust_sha256',f.(rustKey),...
        'original_source_executed',false,'original_error','',...
        'patient_data',false,'native_randperm_one_based',nativePermutation(:)',...
        'arch',computer('arch'));
    try
        % Original source entry point, not a translated alternative.
        lastwarn('','');
        rng(double(inp.seed));
        [originalPredictions,originalPerformance] = cpm_main(X,Y,...
            'pthresh',pthresh,'kfolds',k);
        [warningMessage,warningId] = lastwarn;
        originalPredictions = double(originalPredictions(:));
        originalPerformance = double(originalPerformance(:)');
        assert(numel(originalPredictions)==n && numel(originalPerformance)==2);
        assert(all(isfinite(originalPredictions)) && all(isfinite(originalPerformance)));
        % Separately invoke untouched original source preprocessing and each
        % cpm_train / cpm_test to expose source internals for full comparisons.
        [X2,Y2] = cpm_check_errors(X,Y,k);
        X2 = double(X2);
        assert(isequal(Y,Y2(:)));
        assert(size(X2,2)==n);
        srcModels = struct('fold',{},'held_out_one_based',{},'train_one_based',{},...
            'positive_feature_indices_one_based',{},'negative_feature_indices_one_based',{},...
            'source_feature_r',{},'source_feature_p',{},'train_summary',{},...
            'held_out_summary',{},'robustfit_coefficients',{},...
            'robustfit_coefficients_hex',{},'held_out_predictions',{},'held_out_prediction_hex',{});
        reconstruction = zeros(n,1);
        block = floor(n/k);
        for fold=1:k
            if k==n
                held = nativePermutation(fold);
            else
                held = nativePermutation(1+(fold-1)*block:fold*block);
            end
            train = setdiff(nativePermutation,held);
            [r,p,mask,mdl] = cpm_train(X2(:,train),Y(train),pthresh);
            r = double(r(:)');p = double(p(:)');
            mdl = double(mdl(:)');
            assert(numel(r)==size(X2,1) && numel(p)==size(X2,1));
            assert(numel(mdl)==2 && all(isfinite(mdl)));
            positive = double(find(mask>0)');negative = double(find(mask<0)');
            assert(~isempty(positive) && ~isempty(negative));
            trainSummary = zeros(1,numel(train));
            for i=1:numel(train)
                idx = train(i);
                trainSummary(i) = nanmean(X2(positive,idx))-nanmean(X2(negative,idx));
            end
            heldSummary = zeros(1,numel(held));
            for i=1:numel(held)
                idx = held(i);
                heldSummary(i) = nanmean(X2(positive,idx))-nanmean(X2(negative,idx));
            end
            heldPredictions = double(cpm_test(X2(:,held),mdl',mask));
            heldPredictions = heldPredictions(:)';
            assert(numel(heldPredictions)==numel(held));
            reconstruction(held) = heldPredictions(:);
            srcModels(end+1) = struct('fold',double(fold),... %#ok<AGROW>
                'held_out_one_based',double(held(:)'),...
                'train_one_based',double(train(:)'),...
                'positive_feature_indices_one_based',positive,...
                'negative_feature_indices_one_based',negative,...
                'source_feature_r',r,'source_feature_p',p,...
                'train_summary',trainSummary,...
                'held_out_summary',heldSummary,...
                'robustfit_coefficients',mdl,...
                'robustfit_coefficients_hex',{cellstr(num2hex(mdl(:)))},...
                'held_out_predictions',heldPredictions,...
                'held_out_prediction_hex',{cellstr(num2hex(heldPredictions(:)))});
        end
        omission = nativePermutation(k*block+1:end);
        if k==n,omission=zeros(1,0);end
        assert(numel(omission)==spec.expected_omitted);
        assert(all(originalPredictions(omission)==0));
        reconError = max(abs(reconstruction-originalPredictions));
        record.original_source_executed = true;
        record.source_features_by_subject = double(X2');
        record.source_features_hex = cellstr(num2hex(X2(:)));
        record.original_fold_models = srcModels;
        record.omitted_one_based = double(omission(:)');
        record.original_predictions = double(originalPredictions(:)');
        record.original_prediction_hex = cellstr(num2hex(originalPredictions(:)));
        record.original_performance = originalPerformance;
        record.original_performance_hex = cellstr(num2hex(originalPerformance(:)));
        record.source_self_reconstruction_error = reconError;
        record.source_warning_message = warningMessage;
        record.source_warning_id = warningId;
        healthy = healthy + double(reconError<=1e-9);
        cases(end+1) = struct('case_name',name,'n',n,'k',k,... %#ok<AGROW>
            'original_error','','reconstruction_error',reconError);
    catch exception
        record.original_error = getReport(exception,'extended','hyperlinks','off');
        cases(end+1) = struct('case_name',name,'n',n,'k',k,... %#ok<AGROW>
            'original_error',exception.message,'reconstruction_error',NaN);
    end
    preserve(fullfile(out,[name '.json']),record);
    fprintf('YALE_3D_CPM_MAIN_ORIGINAL %s executed=%d\n',name,record.original_source_executed);
end
report = struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'source_revision',manifest.source_revision,...
    'cases',cases,'healthy_source_reconstructions',healthy,'total_cases',numel(names));
preserve(fullfile(out,'summary.json'),report);
assert(healthy==numel(names),'GENUINE_YALE_3D_CPM_MAIN_ORIGINAL_FAILED');
end

function preserve(path,obj)
f = fopen(path,'w'); assert(f>0);
guard = onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'%s\n',jsonencode(obj));
end
