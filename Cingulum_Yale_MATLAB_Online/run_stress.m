function run_stress
% Genuine MathWorks R2026b original Yale ridge/PCA held-out generalisation gate.
% All inputs/expected Rust outputs are independently generated SYNTHETIC.
% This workflow is separate from the previously accepted fixed 36-case battery.
if exist('OCTAVE_VERSION','builtin')~=0
    error('Original-source held-out stress battery must use genuine MATLAB');
end
root=fileparts(mfilename('fullpath'));
manifest=jsondecode(fileread(fullfile(root,'stress','manifest.json')));
assert(~manifest.patient_data_included);
assert(strcmp(manifest.stopping_policy,'matlab_r2026b_candidate'));
assert(strcmp(version('-release'),'2026b'));
assert(strcmp(manifest.source_commit.yale_cpm,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
required={'lasso','pca','corr','squareform'};
for j=1:numel(required)
    assert(~isempty(which(required{j})),['Required MathWorks function missing: ',required{j}]);
end
toolbox=ver('stats');
assert(~isempty(toolbox));
scenario_names=fieldnames(manifest.scenarios);
all_ok=true;
all_entries=struct('scenario',{},'method',{},'status',{},'subjects',{},'lambda',{},'alpha',{},...
    'max_prediction_difference',{},'max_pca_loading_difference',{},'max_pca_target_difference',{},'error',{});
outdir=fullfile(root,'results','stress');
if ~exist(outdir,'dir');mkdir(outdir);end
for icase=1:numel(scenario_names)
    scenario=scenario_names{icase};
    spec=manifest.scenarios.(scenario).spec;
    path=fullfile(root,'stress',scenario);
    load(fullfile(path,'cohort.mat'),'all_mats','all_behav');
    load(fullfile(path,'pca-targets.mat'),'multi_behav');
    n=size(all_mats,3);
    assert(n==spec.n && n==size(all_behav,1) && n==size(multi_behav,1));
    assert(size(all_mats,1)==8 && size(all_mats,2)==8);
    held_index=(1:n)';
    outcase=fullfile(outdir,scenario);
    if ~exist(outcase,'dir');mkdir(outcase);end
    entry=struct([]);
    for method_id=1:2
        if method_id==1
            mode='ridge';alpha=spec.ridge_alpha;
        else
            mode='pca';alpha=spec.pca_alpha;
        end
        row=struct('scenario',scenario,'method',mode,'status','FAIL',...
            'subjects',n,'lambda',spec.lam,'alpha',alpha,...
            'max_prediction_difference',NaN,'max_pca_loading_difference',NaN,...
            'max_pca_target_difference',NaN,'error','');
        source=struct('runtime','MathWorks MATLAB','release',version('-release'),...
            'statistics_toolbox_version',toolbox.Version,'synthetic_only',true,...
            'original_yale_revision','b903f83b476b745417b1f062f6777f5ffe118f1a',...
            'scenario',scenario,'method',mode,'alpha',alpha,'lambda',spec.lam,...
            'p_threshold',0.05,'fold_protocol','explicit_leave_one_participant_out');
        try
            if method_id==1
                [~,~,~,~,prediction,beta,intercept,lambda_fold] = ...
                    ridgeCPM(all_mats,all_behav,0.05,alpha,spec.lam,held_index,665);
            else
                [~,~,~,~,prediction,latent,loadings,beta,intercept,lambda_fold] = ...
                    ridgeCPM_PCA(all_mats,multi_behav,0.05,alpha,spec.lam,held_index,665);
            end
            source.predictions=prediction(:)';
            source.beta_total=beta;
            source.intercept_total=intercept;
            source.lambda_per_fold=lambda_fold;
            expected=jsondecode(fileread(fullfile(path,['rust-',mode,'.json'])));
            assert(strcmp(expected.config.stopping_policy,'matlab_r2026b_candidate'));
            assert(abs(expected.config.lambda-spec.lam)<1e-12);
            assert(abs(expected.config.alpha-alpha)<1e-12);
            assert(numel(expected.predictions)==n && numel(expected.folds)==n);
            err=strict_vector_error(source.predictions,expected.predictions);
            row.max_prediction_difference=err;
            row.max_pca_loading_difference=0;
            row.max_pca_target_difference=0;
            if method_id==2
                source.pca_loadings=loadings;
                source.observed_fold_components=latent(:)';
                row.max_pca_target_difference=strict_vector_error(source.observed_fold_components,expected.observed_fold_components);
                for fold=1:n
                    row.max_pca_loading_difference=max(row.max_pca_loading_difference,...
                        strict_vector_error(loadings(fold,:),expected.folds(fold).loading));
                end
            end
            if err<=1e-6 && row.max_pca_loading_difference<=1e-6 && row.max_pca_target_difference<=1e-6
                row.status='PASS';
            end
        catch ME
            row.error=[ME.identifier,' ',ME.message];
            source.error=row.error;
        end
        source.checked_status=row.status;
        source.max_prediction_difference=row.max_prediction_difference;
        source.max_pca_target_difference=row.max_pca_target_difference;
        source.max_pca_loading_difference=row.max_pca_loading_difference;
        write_json(fullfile(outcase,['matlab-',mode,'.json']),source);
        entry=[entry,row]; %#ok<AGROW>
        all_entries=[all_entries,row]; %#ok<AGROW>
        fprintf('GENUINE_R2026B_STRESS %s / %s: %s; max discrepancy %.17g\n',...
                scenario,mode,row.status,row.max_prediction_difference);
        if ~strcmp(row.status,'PASS')
            all_ok=false;
            fprintf(2,'FAIL DETAIL %s / %s: %s\n',scenario,mode,row.error);
        end
    end
    write_json(fullfile(outcase,'report.json'),struct('scenario',scenario,'models',entry,...
        'pass',all(strcmp({entry.status},'PASS')),'runtime','MathWorks MATLAB',...
        'release',version('-release'),'toolbox',toolbox.Version));
end
summary=struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'statistics_toolbox',toolbox.Version,'source_revision',...
    'b903f83b476b745417b1f062f6777f5ffe118f1a',...
    'synthetic_only',true,'independently_generated_stress_scenarios',numel(scenario_names),...
    'model_scenario_comparisons',numel(all_entries),'passed',sum(strcmp({all_entries.status},'PASS')),...
    'failed',sum(strcmp({all_entries.status},'FAIL')),...
    'all_pass',all_ok,'cases',all_entries);
write_json(fullfile(outdir,'summary.json'),summary);
if ~all_ok
    error('STRESS_MATLAB_PARITY_FAILED: Preserve all original-source prediction output JSON and exact scientific failures');
end
fprintf('GENUINE_R2026B_YALE_HELDOUT_STRESS_ALL_CASES_PASS %d / %d\n',...
    summary.passed,summary.model_scenario_comparisons);
end

function diff=strict_vector_error(a,b)
    a=double(a(:));b=double(b(:));
    if isempty(a) || numel(a)~=numel(b) || any(~isfinite(a)) || any(~isfinite(b))
        error('Mismatch, empty or non-finite values in original-source comparison');
    end
    diff=max(abs(a-b));
end

function write_json(path,content)
    file=fopen(path,'w');
    if file<0;error('Cannot save original-source scientific evidence');end
    fprintf(file,'%s\n',jsonencode(content));
    fclose(file);
end
