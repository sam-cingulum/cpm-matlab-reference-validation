function report = run_cpm_cv_remainder_original_prospective()
% Genuine MathWorks original Yale cpm_cv.m, unchanged pinned source.
% All six synthetic inputs and independent verification are precommitted
% BEFORE this original-source execution.
if exist('OCTAVE_VERSION','builtin')~=0,error('GENUINE_MATHWORKS_REQUIRED');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
inputRoot=fullfile(root,'cpm_cv_remainder_prospective');
manifest=jsondecode(fileread(fullfile(inputRoot,'manifest.json')));
assert(strcmp(manifest.experiment_id,'yale-cpmcv-remainder-original-source-20261111-v1'));
assert(strcmp(manifest.pinned_source,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.matlab_release,'R2026b') && strcmp(manifest.acceptance_abs,'1e-9'));
assert(~manifest.patient_data && manifest.original_fitting_not_yet_executed);
assert(manifest.bitwise_zero_unassigned);
names=fieldnames(manifest.cases);
assert(numel(names)==6);
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
assert(~isempty(which('cpm_cv')) && ~isempty(which('cpm_train')) && ...
       ~isempty(which('cpm_test')) && ~isempty(which('nanmean')) && ...
       ~isempty(which('robustfit')));
resultDir=fullfile(root,'cpm_cv_remainder_results');
if ~exist(resultDir,'dir'),mkdir(resultDir);end
passCount=0;
entries=struct('case_name',{},'passed',{},'n',{},'k',{},'omitted',{});
inputDigestKey=matlab.lang.makeValidName('input.json');
for ci=1:numel(names)
    name=names{ci};spec=manifest.cases.(name);
    assert(isfield(spec.sha256,inputDigestKey));
    raw=jsondecode(fileread(fullfile(inputRoot,name,'input.json')));
    n=double(raw.n);k=double(raw.k);seed=double(raw.seed);p=double(raw.pthresh);
    X=double(raw.x).';Y=double(raw.y(:));
    assert(size(X,1)==28 && size(X,2)==n && numel(Y)==n);
    assert(n==spec.n && k==spec.k && seed==spec.seed);
    assert(all(isfinite(X),'all') && all(isfinite(Y)) && ...
           p==0.05 && k>=2 && k<=n);
    % This is a source-level annotation of the unchanged original's
    % randperm and non-LOO fixed-size test blocks.
    rng(seed);
    nativePermutation=randperm(n);
    rng(seed);
    predictions=cpm_cv(X,Y,p,k); % The unchanged original source.
    predictions=double(predictions(:));
    assert(numel(predictions)==n);
    predicted=zeros(n,1);
    tested=zeros(n,1);
    ksample=floor(n/k);
    foldModels=struct('fold',{},'held_out_indices',{},'positive_mask_count',{},...
        'negative_mask_count',{},'positive_edge_indices',{}, ...
        'negative_edge_indices',{},'robustfit_coefficients',{}, ...
        'held_out_predictions',{});
    for fold=1:k
        if k==n
            testInds=nativePermutation(fold);
        else
            si=1+(fold-1)*ksample;
            fi=si+ksample-1;
            testInds=nativePermutation(si:fi);
        end
        trainInds=setdiff(nativePermutation,testInds);
        [~,~,pmask,mdl]=cpm_train(X(:,trainInds),Y(trainInds),p);
        assert(all(isfinite(mdl)));
        assert(any(pmask>0) && any(pmask<0));
        foldPred=double(cpm_test(X(:,testInds),mdl,pmask));
        foldPred=foldPred(:);
        assert(numel(foldPred)==numel(testInds) && all(isfinite(foldPred)));
        predicted(testInds)=foldPred;
        tested(testInds)=tested(testInds)+1;
        foldModels(end+1)=struct('fold',fold,... %#ok<AGROW>
            'held_out_indices',double(testInds(:)'),...
            'positive_mask_count',sum(pmask>0),...
            'negative_mask_count',sum(pmask<0),...
            'positive_edge_indices',double(find(pmask>0).'),...
            'negative_edge_indices',double(find(pmask<0).'),...
            'robustfit_coefficients',double(mdl(:)'),...
            'held_out_predictions',double(foldPred(:)'));
    end
    assert(all(tested<=1));
    omitted=double(nativePermutation(k*ksample+1:end));
    if k==n,omitted=zeros(1,0);end
    assert(all(tested(omitted)==0));
    assert(all(predictions(omitted)==0));
    expected=0;
    if k~=n,expected=mod(n,k);end
    assert(numel(omitted)==expected && expected==spec.expected_unassigned);
    diffmax=max(abs(predictions-predicted));
    passes=isfinite(diffmax) && diffmax<=1e-9;
    passCount=passCount+double(passes);
    record=struct('runtime','MathWorks MATLAB',...
        'release',version('-release'),...
        'pinned_yale_source',manifest.pinned_source,...
        'case_name',name,'n',n,'k',k,'seed',seed,...
        'fixture_sha256',spec.sha256.(inputDigestKey),...
        'seeded_original_randperm',double(nativePermutation(:)'),...
        'assigned_indices',double(nativePermutation(1:(n-expected))),...
        'unassigned_indices',double(omitted(:)'),...
        'source_predictions',double(predictions(:)'),...
        'reconstructed_predictions',double(predicted(:)'),...
        'source_fold_reconstruction_pass',passes,...
        'max_source_reconstruction_prediction_error',diffmax,...
        'all_unassigned_exact_zero',all(predictions(omitted)==0),...
        'fold_models',foldModels,...
        'patient_data',false,...
        'original_cpm_cv_executed_unchanged',true);
    persist(fullfile(resultDir,[name '.json']),record);
    entries(end+1)=struct('case_name',name,'passed',passes,'n',n,'k',k,... %#ok<AGROW>
        'omitted',expected);
    fprintf('CPMCV_ORIGINAL_REMAINDER %s n=%d k=%d omitted=%d reconstruction=%d\n',...
        name,n,k,expected,passes);
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'source_revision',manifest.pinned_source,'case_count',numel(names),...
    'source_reconstruction_pass_count',passCount,'cases',entries);
persist(fullfile(resultDir,'summary.json'),report);
if passCount~=6,error('CPMCV_ORIGINAL_SOURCE_RECONSTRUCTION_GATE_FAILED');end
end

function persist(path,obj)
f=fopen(path,'w');assert(f>0);
closer=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(obj));
end
