function report = run_cpmcv_full_original_source_prospective()
% Genuine MathWorks MATLAB R2026b: unchanged pinned Yale cpm_cv.m.
% Actual Rust coefficient/mask/prediction forecasts must already be SHA256
% frozen and committed after an independent randperm-only MathWorks stage.
if exist('OCTAVE_VERSION','builtin')~=0,error('GENUINE_MATHWORKS_REQUIRED');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'cpmcv_full_models_prospective');
manifest=jsondecode(fileread(fullfile(pack,'manifest.json')));
forecasts=jsondecode(fileread(fullfile(pack,'conditional_forecast_manifest.json')));
assert(strcmp(manifest.experiment_id,'yale-cpmcv-full-model-two-stage-20261111-v1'));
assert(strcmp(manifest.source_revision,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.mathworks_release,'R2026b'));
assert(strcmp(manifest.coefficient_abs_tolerance,'1e-9'));
assert(strcmp(manifest.prediction_abs_tolerance,'1e-8'));
assert(strcmp(manifest.source_self_reconstruction_abs_tolerance,'1e-9'));
assert(manifest.exact_edge_masks && manifest.exact_historical_zero_placeholders);
assert(manifest.synthetic_only && manifest.original_source_not_executed);
assert(strcmp(forecasts.experiment_id,manifest.experiment_id));
assert(strcmp(forecasts.original_source_revision,manifest.source_revision));
assert(forecasts.source_predictions_frozen_before_original_matlab && ...
    forecasts.original_source_not_executed && ~forecasts.patient_data);
names=fieldnames(manifest.cases);
assert(numel(names)==8 && numel(fieldnames(forecasts.cases))==8);
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
assert(~isempty(which('cpm_cv')) && ~isempty(which('cpm_train')) && ...
    ~isempty(which('cpm_test')) && ~isempty(which('robustfit')));
outdir=fullfile(root,'cpmcv_full_models_original_results');
if ~exist(outdir,'dir'),mkdir(outdir);end
inputKey=matlab.lang.makeValidName('input.json');
nativeKey=matlab.lang.makeValidName('native_randperm.json');
rustKey=matlab.lang.makeValidName('rust_source.json');
entries=struct('case_name',{},'n',{},'k',{},'original_source_consistent',{},...
               'max_source_reconstruction_error',{});
pass=0;
for ci=1:numel(names)
    name=names{ci};
    spec=manifest.cases.(name);
    digest=forecasts.cases.(name).sha256;
    assert(isfield(spec.sha256,inputKey) && ...
        isfield(digest,nativeKey) && isfield(digest,rustKey));
    inp=jsondecode(fileread(fullfile(pack,name,'input.json')));
    X=double(inp.x).';Y=double(inp.y(:));
    n=size(X,2);d=size(X,1);
    k=double(inp.k);seed=double(inp.seed);p=double(inp.pthresh);
    assert(n==spec.n && d==28 && k==spec.k && seed==spec.seed && p==0.05);
    assert(numel(Y)==n && all(isfinite(X),'all') && all(isfinite(Y)));
    native=jsondecode(fileread(fullfile(pack,name,'native_randperm.json')));
    assert(strcmp(native.runtime,'MathWorks MATLAB') && ...
        strcmp(native.release,'2026b') && native.source_not_run && native.model_fit_not_run);
    assert(strcmp(native.case_name,name) && strcmp(native.input_sha256,spec.sha256.(inputKey)));
    rng(seed);
    perm=double(randperm(n));
    assert(isequal(perm(:),double(native.randperm_one_based(:))));
    rust=jsondecode(fileread(fullfile(pack,name,'rust_source.json')));
    assert(strcmp(rust.policy,'yale_source_compatibility'));
    assert(numel(rust.fold_models)==k && numel(rust.predictions)==n);
    rng(seed);
    % Invoke original Yale source UNCHANGED.
    original=double(cpm_cv(X,Y,p,k));
    original=original(:);
    assert(numel(original)==n && all(isfinite(original)));
    % Original source-based audit: independently re-run each actual
    % training/test fold with unchanged original cpm_train/cpm_test.
    reconstructed=zeros(n,1);
    models=struct('fold',{},'held_out_indices_one_based',{}, ...
        'positive_edge_indices_one_based',{},'negative_edge_indices_one_based',{},...
        'robustfit_coefficients',{},'robustfit_coefficients_hex',{},...
        'held_out_predictions',{},'held_out_predictions_hex',{});
    block=floor(n/k);
    for fold=1:k
        if k==n
            held=perm(fold);
        else
            held=perm(1+(fold-1)*block : fold*block);
        end
        train=setdiff(perm,held);
        [~,~,pmask,mdl]=cpm_train(X(:,train),Y(train),p);
        assert(all(isfinite(mdl)));
        assert(any(pmask>0) && any(pmask<0));
        prediction=double(cpm_test(X(:,held),mdl,pmask));
        prediction=prediction(:);
        assert(numel(prediction)==numel(held) && all(isfinite(prediction)));
        reconstructed(held)=prediction;
        models(end+1)=struct('fold',fold,... %#ok<AGROW>
            'held_out_indices_one_based',double(held(:)'),...
            'positive_edge_indices_one_based',double(find(pmask>0).'),...
            'negative_edge_indices_one_based',double(find(pmask<0).'),...
            'robustfit_coefficients',double(mdl(:)'),...
            'robustfit_coefficients_hex',{cellstr(num2hex(double(mdl(:))))},...
            'held_out_predictions',double(prediction(:)'),...
            'held_out_predictions_hex',{cellstr(num2hex(prediction(:)))});
    end
    omitted=perm(k*block+1:end);
    if k==n,omitted=zeros(1,0);end
    assert(numel(omitted)==spec.expected_omitted);
    assert(all(original(omitted)==0));
    maxerr=max(abs(original-reconstructed));
    consistent=isfinite(maxerr) && maxerr<=1e-9;
    pass=pass+double(consistent);
    artifact=struct('runtime','MathWorks MATLAB',...
        'release',version('-release'),...
        'source_revision',manifest.source_revision,...
        'case_name',name,'n',n,'k',k,...
        'fixture_sha256',spec.sha256.(inputKey),...
        'native_randperm_sha256',digest.(nativeKey),...
        'frozen_rust_source_sha256',digest.(rustKey),...
        'native_randperm_one_based',double(perm(:)'),...
        'original_unassigned_one_based',double(omitted(:)'),...
        'original_predictions',double(original(:)'),...
        'original_prediction_hex',{cellstr(num2hex(original(:)))},...
        'original_fold_models',models,...
        'max_source_reconstruction_error',maxerr,...
        'source_self_reconstruction_pass',consistent,...
        'patient_data',false,...
        'original_source_unmodified',true);
    persist(fullfile(outdir,[name '.json']),artifact);
    entries(end+1)=struct('case_name',name,'n',n,'k',k,... %#ok<AGROW>
       'original_source_consistent',consistent,'max_source_reconstruction_error',maxerr);
    fprintf('CPMCV_FULL_SOURCE %s n=%d k=%d omitted=%d self_recon=%.4g\n',...
        name,n,k,numel(omitted),maxerr);
end
report=struct('runtime','MathWorks MATLAB',...
    'release',version('-release'),...
    'source_revision',manifest.source_revision,...
    'case_count',numel(names),...
    'source_self_reconstruction_pass_count',pass,...
    'cases',entries);
persist(fullfile(outdir,'summary.json'),report);
if pass~=8,error('CPMCV_FULL_SOURCE_RECONSTRUCTION_GATE_FAILED_ARTIFACTS_PRESERVED');end
end

function persist(path,obj)
f=fopen(path,'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(obj));
end
