function report = run_find_lambda_b64_v2_b64_v2()
% Original pinned Yale find_lambda.m from the unmodified upstream checkout.
% Two distinct authentic MathWorks executions, not post-hoc forecasts:
% A) crossvalind-only produces native labels, before original model fitting.
% B) genuine native labels and actual Rust model forecasts are SHA256-frozen
%    and publicly committed BEFORE this unchanged original-source execution.
% No implicit MATLAB RNG equivalence is claimed.
if exist('OCTAVE_VERSION','builtin')~=0
    error('MATLAB_ONLY: only MathWorks MATLAB is permitted');
end
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'find_lambda_b64_v2');
m=jsondecode(fileread(fullfile(pack,'manifest.json')));
f=jsondecode(fileread(fullfile(pack,'conditional_forecast_manifest.json')));
assert(strcmp(version('-release'),'2026b'));
assert(~m.patient_data_included && m.original_source_unmodified);
assert(strcmp(m.original_yale_revision,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(f.experiment_id,'yale-find-lambda-two-stage-20261111-v1'));
assert(strcmp(f.original_yale_sha,m.original_yale_revision));
assert(strcmp(f.release,'R2026b') && ~f.patient_data);
assert(f.original_source_has_not_been_executed_at_forecast_freeze);
assert(f.original_source_thresholds_unchanged);
assert(numel(fieldnames(f.cases))==numel(fieldnames(m.cases)));
assert(m.coefficients_absolute_tolerance==1e-9);
assert(m.intercept_absolute_tolerance==1e-9);
assert(m.predictions_absolute_tolerance==1e-6);
assert(m.mse_absolute_tolerance==1e-6);
assert(m.test_full_mse_fold_matrix && m.test_all_edge_masks);
assert(m.selected_lambda_must_match_exact && m.native_matlab_crossvalind_labels_retained);
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
assert(~isempty(which('find_lambda')) && ~isempty(which('lasso')) && ...
    ~isempty(which('crossvalind')));
toolbox=ver('stats');
assert(~isempty(toolbox));
dst=fullfile(root,'find_lambda_b64_v2_original_results');
if ~exist(dst,'dir'),mkdir(dst);end
names=fieldnames(m.cases);
items=struct('case_name',{},'subject_count',{},'folds',{},'lambdas',{}, ...
    'source_consistent',{},'max_source_self_mse_error',{});
all_ok=true;
for ci=1:numel(names)
    name=names{ci};
    input=jsondecode(fileread(fullfile(pack,name,'input.json')));
    rows=input.dataset.observations;
    n=numel(rows);
    X=zeros(28,n);
    y=zeros(n,1);
    for i=1:n
        x=double(rows(i).edges(:));
        assert(numel(x)==28);
        X(:,i)=x;
        y(i)=double(rows(i).outcome);
    end
    k=double(input.k);
    seed=double(input.seed);
    original_grid=double(input.lambda_grid(:));
    grid=sort(original_grid,'descend');
    p=double(input.p_threshold);
    assert(k>=2 && k<=n);
    assert(numel(grid)>=2 && numel(unique(grid))==numel(grid));
    % Source uses crossvalind but does not reset rng internally.
    % Emit actual seeded MathWorks native fold IDs in original row order.
    rng(seed);
    indices=crossvalind('Kfold',n,k);
    indices=double(indices(:));
    assert(numel(indices)==n && all(indices>=1 & indices<=k));
    assert(all(histcounts(indices,0.5:1:(k+0.5))>0));
    % The native MathWorks fold IDs and the actual Rust forecasts MUST have
    % been published before this step. Never use source outputs to create
    % or adjust Rust forecasts.
    native=jsondecode(fileread(fullfile(pack,name,'native_fold_labels.json')));
    assert(strcmp(native.runtime,'MathWorks MATLAB'));
    assert(strcmp(native.release,'2026b'));
    assert(native.source_not_run && native.model_fit_not_run);
    assert(native.complete_partition && ~native.patient_data_included);
    assert(strcmp(native.case_name,name));
    assert(native.seed==seed && native.n==n && native.k==k);
    assert(isequal(double(native.labels(:)),indices),...
        'STAGE_B_NATIVE_FOLD_IDENTITY_FAILURE');
    rust=jsondecode(fileread(fullfile(pack,name,'rust.json')));
    assert(strcmp(rust.source_method,'find_lambda.m'));
    assert(isequal(double(rust.matlab_crossvalind_labels(:)),indices));
    assert(numel(rust.fold_details)==k*numel(grid));
    request=jsondecode(fileread(fullfile(pack,name,'conditional_request.json')));
    assert(isequal(double(request.matlab_crossvalind_labels(:)),indices));
    assert(request.k==k && request.p_threshold==p);
    rng(seed);
    [chosen,mse]=find_lambda(X,y,original_grid,p,k);
    assert(isequal(size(mse),[k,numel(grid)]));
    original_mean=mean(mse,1);
    original_se=std(mse,0,1)/sqrt(k);
    [~,min_idx]=min(original_mean);
    [~,se_idx]=max(original_mean<=original_mean(min_idx)+original_se(min_idx));
    chosen_again=grid(se_idx);
    if se_idx==1,chosen_again=grid(min_idx);end
    assert(isscalar(chosen) && chosen==chosen_again);
    details=struct('lambda',{},'fold',{},'held_out_indices',{}, ...
        'selected_edge_indices',{},'coefficients',{},'intercept',{}, ...
        'held_out_predictions',{},'mse',{});
    max_mse_error=0;
    for li=1:numel(grid)
        lambda=grid(li);
        for fold=1:k
            held=find(indices==fold);
            train=find(indices~=fold);
            trainX=X(:,train);
            trainY=y(train);
            [~,edgep]=corr(trainX',trainY);
            eligible=find(edgep<=p);
            if size(trainX,1)<300
                [beta,info]=lasso(trainX(eligible,:)',trainY, ...
                    'Alpha',1e-9,'Lambda',lambda);
            else
                [beta,info]=lasso(trainX(eligible,:)',trainY, ...
                    'Alpha',1e-9,'Lambda',lambda,'RelTol',1e-3,'MaxIter',100);
            end
            pred=X(eligible,held)'*beta+info.Intercept;
            loss=mean((pred-y(held)).^2);
            delta=abs(loss-mse(fold,li));
            max_mse_error=max(max_mse_error,delta);
            details(end+1)=struct('lambda',lambda,'fold',fold, ... %#ok<AGROW>
                'held_out_indices',double(held(:)'-1), ...
                'selected_edge_indices',double(eligible(:)'-1), ...
                'coefficients',double(beta(:)'), ...
                'intercept',double(info.Intercept), ...
                'held_out_predictions',double(pred(:)'), ...
                'mse',double(loss));
        end
    end
    consistent=isfinite(max_mse_error) && max_mse_error<=m.mse_absolute_tolerance;
    all_ok=all_ok && consistent;
    item=struct('case_name',name,'subject_count',n,'folds',k, ...
        'lambdas',numel(grid),'source_consistent',consistent, ...
        'max_source_self_mse_error',max_mse_error);
    items(end+1)=item; %#ok<AGROW>
    fileShaNames=f.cases.(name).sha256;
    frozenLabelDigestKey=matlab.lang.makeValidName('native_fold_labels.json');
    frozenRustDigestKey=matlab.lang.makeValidName('rust.json');
    assert(isfield(fileShaNames,frozenLabelDigestKey));
    assert(isfield(fileShaNames,frozenRustDigestKey));
    artifact=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
        'toolbox_version',toolbox.Version,'original_source_revision',m.original_yale_revision, ...
        'case_name',name,'native_matlab_crossvalind_labels',double(indices(:)'), ...
        'frozen_native_fold_labels_sha256',fileShaNames.(frozenLabelDigestKey), ...
        'frozen_actual_rust_forecast_sha256',fileShaNames.(frozenRustDigestKey), ...
        'original_source_executed_only_after_forecast_freeze',true, ...
        'lambda_grid_descending',double(grid(:)'), ...
        'original_source_selected_lambda',double(chosen), ...
        'original_source_mse_fold',double(mse), ...
        'original_mean_mse',double(original_mean(:)'), ...
        'original_se_mse',double(original_se(:)'), ...
        'original_source_fold_models',details, ...
        'original_function_self_consistent',consistent, ...
        'max_source_self_mse_error',max_mse_error,'patient_data_included',false);
    write_json(fullfile(dst,[name '.json']),artifact);
    fprintf('ORIGINAL_FIND_LAMBDA %s n=%d k=%d lambdas=%d selected=%.16g source_mse_err=%.3g\n', ...
        name,n,k,numel(grid),chosen,max_mse_error);
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
    'original_yale_sha',m.original_yale_revision, ...
    'toolbox_version',toolbox.Version,'patient_data_included',false, ...
    'case_count',numel(items),'cases',items, ...
    'all_original_function_self_consistent',all_ok, ...
    'not_a_claim_of_rust_matlab_rng_parity',true);
write_json(fullfile(dst,'summary.json'),report);
if ~all_ok
    error('ORIGINAL_YALE_FIND_LAMBDA_SELF_CONSISTENCY_FAIL: artifacts preserved');
end
end
function write_json(path,obj)
fid=fopen(path,'w');
if fid<0,error('Cannot save unmodified original source evidence');end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(obj));
end
