function output = diagnose_lasso()
% R2026b synthetic-only STOPPING DIAGNOSTIC. Yale's source remains unmodified.
% This probe calls MathWorks lasso directly on exactly the train-fold-selected
% inputs used by the pinned original ridgeCPM/ridgeCPM_PCA functions.
% It never declares source parity: the results are for mechanism identification.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('Genuine MATLAB required');
end
root = fileparts(mfilename('fullpath'));
load(fullfile(root,'fixtures','baseline','cohort.mat'),'all_mats','all_behav');
load(fullfile(root,'fixtures','baseline','pca-targets.mat'),'multi_behav');
N = size(all_mats,3);
assert(N == 48);
E = size(all_mats,1) * (size(all_mats,1)-1) / 2;
edges = zeros(E,N);
for k = 1:N
    edges(:,k) = squareform(tril(all_mats(:,:,k),-1));
end
output = struct();
output.runtime = 'MathWorks MATLAB';
output.release = version('-release');
output.toolbox = ver('stats');
output.data_type = 'synthetic_only';
output.scenario = 'baseline';
output.source_commit = 'b903f83b476b745417b1f062f6777f5ffe118f1a';
output.purpose = 'Investigate stopping semantics, not source parity';
output.cases = struct([]);
steps = [1,2,5,25,80,100,115,120,124,128,132,136,140,145,150,155,160,180,220];
held = [1,2,12,24,36,48];
for method_num = 1:2
    if method_num == 1
        method = 'ridge-compat';
        alpha = 1e-9;
    else
        method = 'pca';
        alpha = 1e-6;
    end
    for held_index = held
        train = true(N,1);
        train(held_index) = false;
        X = edges(:,train)';
        if method_num == 1
            y = all_behav(train);
        else
            [pc,~,~,~,~] = pca(multi_behav(train,:),'NumComponents',1);
            y = multi_behav(train,:) * pc(:,1);
        end
        [~,p] = corr(X,y);
        if method_num == 1
            selected = find(p <= .05);
        else
            selected = find(p < .05);
        end
        assert(numel(selected)>0);
        X = X(:,selected);
        args = {'Alpha',alpha,'Lambda',0.1};
        [base, basefit] = lasso(X,y,args{:});
        case_row = struct();
        case_row.method = method;
        case_row.held_out_zero_based = held_index-1;
        case_row.train_subjects = sum(train);
        case_row.selected_edges_matlab_one_based = selected(:)';
        case_row.alpha = alpha;
        case_row.lambda = 0.1;
        case_row.base_coefficients = base(:)';
        case_row.base_intercept = basefit.Intercept;
        case_row.base_uses_covariance = basefit.UseCovariance;
        variants = struct([]);
        for usecov = [false,true]
            for tol = [1e-3,1e-4,1e-5,1e-6]
                [b,fit] = lasso(X,y,args{:},'RelTol',tol,'UseCovariance',usecov);
                v = struct('use_covariance_requested',usecov,'use_covariance_actual',fit.UseCovariance,...
                    'relative_tolerance',tol,'coefficients',b(:)',...
                    'intercept',fit.Intercept,'max_abs_diff_from_default',max(abs(b(:)-base(:))));
                variants = [variants,v]; %#ok<AGROW>
            end
        end
        case_row.variants = variants;
        sweep = struct([]);
        for ni = 1:numel(steps)
            lastwarn('');
            [b,fit] = lasso(X,y,args{:},'MaxIter',steps(ni));
            [message, warning_id] = lastwarn;
            item = struct('max_iterations_requested',steps(ni),...
                'coefficient_vector',b(:)','intercept',fit.Intercept,...
                'uses_covariance',fit.UseCovariance,...
                'max_abs_diff_from_default',max(abs(b(:)-base(:))),...
                'warning_id',warning_id,'warning_message',message);
            sweep = [sweep,item]; %#ok<AGROW>
        end
        case_row.maxiter_sweep = sweep;
        output.cases = [output.cases,case_row]; %#ok<AGROW>
        fprintf('MATLAB_DIAG %s held=%d edges=%d cov=%d\n',method,held_index-1,numel(selected),basefit.UseCovariance);
    end
end
assert(numel(output.cases)==12);
dest = fullfile(root,'results','diagnostics');
if ~exist(dest,'dir');mkdir(dest);end
f = fopen(fullfile(dest,'stopping_probe.json'),'w');
if f<0;error('Cannot open diagnostic JSON');end
fprintf(f,'%s\n',jsonencode(output));
fclose(f);
fprintf('Saved 12 genuine MATLAB lasso stopping diagnostic cases\n');
end
