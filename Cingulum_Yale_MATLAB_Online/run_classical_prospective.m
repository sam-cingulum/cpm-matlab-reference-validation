function gate = run_classical_prospective()
% Pre-registered original Yale CPM main/OHBM fold-level scientific parity.
% Synthetic expectations were frozen before running MathWorks MATLAB.
% Pinned ORIGINAL upstream functions remain unmodified. Supplemental fold
% audit invokes original cpm_train/cpm_test, corr/partialcorr and regress.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('MATLAB_ONLY: Genuine MathWorks MATLAB required');
end
root = fileparts(mfilename('fullpath'));
pack = fullfile(root,'classical_prospective');
manifest = jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(manifest.expected_mathworks_release,'R2026b'));
assert(~manifest.patient_data_included);
assert(manifest.require_exact_edge_masks && manifest.require_all_folds);
expected = {'main','ohbm','partial-pearson','partial-spearman'};
assert(isequal(string(manifest.method_profiles(:)),string(expected(:))));
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
addpath(fullfile(root,'upstream','yale-ohbm'));
for f = {'robustfit','regress','partialcorr','corr','cpm_main','cpm_train', ...
         'cpm_test','kfold_cpm_withmatrix','kfold_cpm_partial_withmatrix'}
    assert(~isempty(which(f{1})), ['MISSING_FUNCTION: ' f{1}]);
end
toolbox = ver('stats');
assert(~isempty(toolbox), 'MISSING_MATHWORKS_STATISTICS_TOOLBOX');
release = version('-release');
assert(strcmp(release,'2026b'), 'WRONG_RELEASE');
resultDir = fullfile(root,'classical_results');
if ~exist(resultDir,'dir'), mkdir(resultDir); end
scenarios = fieldnames(manifest.scenarios);
allpass = true;
cases = struct('scenario',{},'profile',{},'subjects',{},'folds',{}, ...
    'pass',{},'max_abs_model_coefficient_error',{}, ...
    'max_abs_intercept_error',{},'max_abs_prediction_error',{}, ...
    'max_abs_independently_derived_prediction_error',{}, ...
    'mask_mismatches',{},'failed_folds',{});
for si = 1:numel(scenarios)
    scenario = scenarios{si};
    in = fullfile(pack,scenario);
    cohort = load(fullfile(in,'cohort.mat'),'all_mats','all_behav','all_covar');
    mats = cohort.all_mats;
    y = cohort.all_behav(:);
    covar = cohort.all_covar;
    n = numel(y);
    assert(n == manifest.scenarios.(scenario).spec.n);
    assert(isequal(size(mats),[8,8,n]));
    X = zeros(n,28);
    ei = 0;
    for a = 1:7
        for b = a+1:8
            ei = ei+1;
            X(:,ei) = reshape(mats(a,b,:),[],1);
        end
    end
    assert(ei == 28);
    for pi = 1:numel(expected)
        profile = expected{pi};
        rust = jsondecode(fileread(fullfile(in,['rust-' profile '.json'])));
        assert(numel(rust.predictions)==n);
        if any(strcmp(profile,{'main','ohbm'}))
            folds = rust.fold_details;
        else
            folds = rust.folds;
        end
        assert(numel(folds)==n);
        if strcmp(profile,'main')
            source_predictions = cpm_main(mats,y,'pthresh',0.05,'kfolds',n);
        elseif strcmp(profile,'ohbm')
            [~,~,~,~,source_predictions] = kfold_cpm_withmatrix(mats,y,n,1,0.05,'Pearson');
        else
            association = 'Pearson';
            if strcmp(profile,'partial-spearman'), association='Spearman'; end
            [~,~,~,~,source_predictions] = kfold_cpm_partial_withmatrix(mats,y,covar,n,1,0.05,association);
        end
        source_predictions = double(source_predictions(:));
        rust_predictions = double(rust.predictions(:));
        prediction_error = max(abs(source_predictions-rust_predictions));
        max_coeff_error=0; max_intercept_error=0;
        max_derived_prediction_error=0; mask_mismatches=0; badfolds=0;
        evidence_folds = repmat(struct('held_out_index',0,'positive_edges',[], ...
            'negative_edges',[],'edge_coefficients',[], ...
            'intercept',0,'source_train_test_prediction',0, ...
            'mask_equal',false,'coefficient_abs_error',0, ...
            'intercept_abs_error',0,'derived_prediction_abs_error',0, ...
            'pass',false), n, 1);
        for i=1:n
            held = folds(i).held_out_indices;
            assert(numel(held)==1 && held(1)==i-1, ...
                'RUST_FOLD_ORDER_NOT_HELD_OUT_ROW_ORDER');
            train = true(n,1);train(i)=false;
            if strcmp(profile,'main')
                original_features = reshape(mats(:,:,train),64,n-1);
                [~,~,pmask,mdl] = cpm_train(original_features,y(train),0.05);
                derived = cpm_test(reshape(mats(:,:,i),64,1),mdl,pmask);
                pos = []; neg = [];
                for a=1:7
                    for b=a+1:8
                        e = (a-1)*(16-a)/2 + (b-a); % 1-based row-major
                        v = pmask(sub2ind([8,8],a,b));
                        if v>0, pos(end+1)=e-1; end %#ok<AGROW>
                        if v<0, neg(end+1)=e-1; end %#ok<AGROW>
                    end
                end
                pos_slope = mdl(2) / numel(pos);
                neg_slope = -mdl(2) / numel(neg);
                intercept = mdl(1);
                fit = folds(i).fit;
                coef_err = max(abs([pos_slope-double(fit.positive_slope), ...
                    neg_slope-double(fit.negative_slope), ...
                    mdl(2)-double(fit.mean_difference_slope)]));
            else
                Xt = X(train,:); yt = y(train);
                if strcmp(profile,'ohbm')
                    [r,p] = corr(Xt,yt,'type','Pearson');
                else
                    association = 'Pearson';
                    if strcmp(profile,'partial-spearman'),association='Spearman';end
                    [r,p] = partialcorr(Xt,yt,covar(train,:),'type',association);
                end
                pos = find(r>0 & p<0.05)' - 1;
                neg = find(r<0 & p<0.05)' - 1;
                sumpos = sum(Xt(:,pos+1),2);
                sumneg = sum(Xt(:,neg+1),2);
                b = regress(yt,[sumpos,sumneg,ones(n-1,1)]);
                intercept = b(3);
                pos_slope = b(1);
                neg_slope = b(2);
                derived = b(1)*sum(X(i,pos+1),2) + ...
                          b(2)*sum(X(i,neg+1),2) + b(3);
                fit = folds(i).fit;
                coef_err = max(abs([pos_slope-double(fit.positive_slope), ...
                    neg_slope-double(fit.negative_slope)]));
            end
            pos = double(pos(:)');
            neg = double(neg(:)');
            rust_pos = double(folds(i).positive_edges(:)');
            rust_neg = double(folds(i).negative_edges(:)');
            same_mask = isequal(pos,rust_pos) && isequal(neg,rust_neg);
            if ~same_mask,mask_mismatches=mask_mismatches+1;end
            intercept_error=abs(intercept-double(fit.intercept));
            derived_error=abs(double(derived)-rust_predictions(i));
            max_coeff_error=max(max_coeff_error,coef_err);
            max_intercept_error=max(max_intercept_error,intercept_error);
            max_derived_prediction_error=max(max_derived_prediction_error,derived_error);
            vec=zeros(1,28);
            vec(pos+1)=pos_slope;
            vec(neg+1)=neg_slope;
            ok = same_mask && isfinite(coef_err) && coef_err<=manifest.full_coefficients_abs_tolerance && ...
                isfinite(intercept_error) && intercept_error<=manifest.intercept_abs_tolerance && ...
                isfinite(derived_error) && derived_error<=manifest.held_out_prediction_abs_tolerance;
            if ~ok,badfolds=badfolds+1;end
            evidence_folds(i)=struct('held_out_index',i-1, ...
                'positive_edges',pos,'negative_edges',neg, ...
                'edge_coefficients',vec,'intercept',double(intercept), ...
                'source_train_test_prediction',double(derived), ...
                'mask_equal',same_mask,'coefficient_abs_error',coef_err, ...
                'intercept_abs_error',intercept_error, ...
                'derived_prediction_abs_error',derived_error,'pass',ok);
        end
        passed = badfolds==0 && isfinite(prediction_error) && ...
            prediction_error<=manifest.held_out_prediction_abs_tolerance;
        allpass=allpass && passed;
        item = struct('scenario',scenario,'profile',profile,'subjects',n,'folds',n, ...
            'pass',passed,'max_abs_model_coefficient_error',max_coeff_error, ...
            'max_abs_intercept_error',max_intercept_error, ...
            'max_abs_prediction_error',prediction_error, ...
            'max_abs_independently_derived_prediction_error',max_derived_prediction_error, ...
            'mask_mismatches',mask_mismatches,'failed_folds',badfolds);
        cases(end+1)=item; %#ok<AGROW>
        evidence = struct('runtime','MathWorks MATLAB','release',release, ...
            'runtime_version',version,'toolbox_version',toolbox.Version, ...
            'source_commit',manifest.source_commit,'scenario',scenario, ...
            'profile',profile,'patient_data_included',false, ...
            'original_predictions',source_predictions(:)', ...
            'folds',evidence_folds,'verdict',item);
        write_json(fullfile(resultDir,[scenario '__' profile '.json']),evidence);
        fprintf('CLASSICAL %s %s: %d/%d folds; max coefficient %.6g, predictions %.6g, masks %d wrong\n', ...
            scenario,profile,n-badfolds,n,max_coeff_error,prediction_error,mask_mismatches);
    end
end
gate=struct('runtime','MathWorks MATLAB','release',release, ...
    'toolbox_version',toolbox.Version,'source_commit',manifest.source_commit, ...
    'patient_data_included',false,'cases',cases,'all_pass',allpass, ...
    'method_comparisons',numel(cases), ...
    'independent_fold_comparisons',sum([cases.folds]), ...
    'total_failed_folds',sum([cases.failed_folds]));
write_json(fullfile(resultDir,'summary.json'),gate);
if ~allpass
    error('CLASSICAL_PROSPECTIVE_STRICT_PARITY_FAILED: archived unchanged raw evidence');
end
end

function write_json(path,value)
fid = fopen(path,'w');
if fid<0,error('Cannot persist original MATLAB evidence');end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(value));
end
