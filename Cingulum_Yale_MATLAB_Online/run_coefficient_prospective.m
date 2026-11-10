function run_coefficient_prospective
% Immutable, unconsulted synthetic R2026b source coefficient parity gate.
% This function does not modify the original Yale methods, historical
% source outputs, Rust expectations or their SHA256-locked input fixtures.
% Full 28-edge coefficient vectors and held-out intercepts MUST pass 1e-9.
if exist('OCTAVE_VERSION','builtin')~=0
 error('Genuine MathWorks MATLAB required for prospective source parity');
end
root=fileparts(mfilename('fullpath'));
manifest=jsondecode(fileread(fullfile(root,'coefficient_prospective','manifest.json')));
assert(~manifest.patient_data_included);
assert(manifest.original_yale_files_unmodified);
assert(manifest.hypothesis_selection_excluded_this_battery);
assert(strcmp(manifest.purpose,'PROSPECTIVE_FROZEN_COEFFICIENT_AND_PREDICTION_PARITY'));
assert(strcmp(manifest.stopping_policy,'matlab_r2026b_active_set_experimental'));
assert(strcmp(version('-release'),'2026b'));
assert(strcmp(manifest.source_commit.yale_cpm,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(manifest.strict_full_coefficient_abs_tolerance==1e-9);
assert(manifest.strict_intercept_abs_tolerance==1e-9);
assert(manifest.original_prediction_abs_tolerance==1e-6);
assert(manifest.original_pca_quantity_abs_tolerance==1e-6);
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
for required={'lasso','pca','corr','squareform'}
 assert(~isempty(which(required{1})),['Genuine source dependency unavailable: ',required{1}]);
end
toolbox=ver('stats');
assert(~isempty(toolbox) && strcmp(toolbox.Version,'26.2'));
scenario_names=fieldnames(manifest.scenarios);
assert(numel(scenario_names)==12);
outdir=fullfile(root,'results','coefficient_prospective');
if ~exist(outdir,'dir');mkdir(outdir);end
records=struct([]);
all_pass=true;
total_folds=0;
coefficient_folds_pass=0;
for i=1:numel(scenario_names)
 name=scenario_names{i};
 spec=manifest.scenarios.(name).spec;
 path=fullfile(root,'coefficient_prospective',name);
 load(fullfile(path,'cohort.mat'),'all_mats','all_behav');
 load(fullfile(path,'pca-targets.mat'),'multi_behav');
 n=size(all_mats,3);
 assert(n==spec.n && size(all_mats,1)==8 && size(all_mats,2)==8);
 assert(numel(all_behav)==n && size(multi_behav,1)==n);
 assert(size(multi_behav,2)==2);
 held=(1:n)';
 caseout=fullfile(outdir,name);
 if ~exist(caseout,'dir');mkdir(caseout);end
 for imethod=1:2
  if imethod==1
   mode='ridge';alpha=spec.ridge_alpha;
  else
   mode='pca';alpha=spec.pca_alpha;
  end
  source=struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'statistics_toolbox_version',toolbox.Version,'synthetic_only',true,...
    'original_yale_revision','b903f83b476b745417b1f062f6777f5ffe118f1a',...
    'scenario',name,'method',mode,'alpha',alpha,'lambda',spec.lam,...
    'fold_protocol','leave_one_participant_out',...
    'coefficient_abs_tolerance',manifest.strict_full_coefficient_abs_tolerance,...
    'intercept_abs_tolerance',manifest.strict_intercept_abs_tolerance,...
    'prediction_abs_tolerance',manifest.original_prediction_abs_tolerance);
  row=struct('scenario',name,'method',mode,'status','FAIL',...
    'subjects',n,'alpha',alpha,'lambda',spec.lam,...
    'max_coefficient_difference',NaN,'max_intercept_difference',NaN,...
    'max_prediction_difference',NaN,'max_pca_loading_difference',NaN,...
    'max_pca_target_difference',NaN,'coefficient_fold_pass_count',0,...
    'failed_coefficient_folds_zero_based',[],'error','');
  try
   if imethod==1
    [~,~,~,~,prediction,beta,intercept,lambda_fold] = ...
      ridgeCPM(all_mats,all_behav,0.05,alpha,spec.lam,held,665);
   else
    [~,~,~,~,prediction,latent,loadings,beta,intercept,lambda_fold] = ...
      ridgeCPM_PCA(all_mats,multi_behav,0.05,alpha,spec.lam,held,665);
   end
   % Preserve authentic MATLAB values BEFORE independent Rust comparison.
   source.predictions=prediction(:)';
   source.beta_total=beta;
   source.intercept_total=intercept;
   source.lambda_per_fold=lambda_fold;
   if imethod==2
    source.pca_loadings=loadings;
    source.observed_fold_components=latent(:)';
   end
   expected=jsondecode(fileread(fullfile(path,['rust-',mode,'.json'])));
   assert(strcmp(expected.config.stopping_policy,'matlab_r2026b_active_set_experimental'));
   assert(expected.config.reltol==0.0001);
   assert(abs(expected.config.alpha-alpha)<1e-12 && abs(expected.config.lambda-spec.lam)<1e-12);
   assert(numel(expected.predictions)==n && numel(expected.folds)==n);
   assert(all(size(beta)==[28,n]));
   assert(numel(intercept)==n);
   expected_beta=zeros(28,n);
   expected_intercept=zeros(1,n);
   for k=1:n
    fold=expected.folds(k);
    selected=double(fold.reference_selected_edge_indices(:))+1;
    coeff=double(fold.reference_coefficients(:));
    assert(numel(selected)==numel(coeff) && numel(selected)==double(fold.selected_edges));
    assert(all(isfinite(coeff)) && all(selected>=1) && all(selected<=28));
    assert(numel(unique(selected))==numel(selected));
    if imethod==2
     assert(numel(fold.held_out_indices)==1 && fold.held_out_indices==k-1);
    else
     assert(numel(fold.held_out_ids)==1);
    end
    expected_beta(selected,k)=coeff;
    expected_intercept(k)=double(fold.reference_intercept);
   end
   assert(all(isfinite(expected_beta(:))) && all(isfinite(expected_intercept(:))));
   coef_error=max(abs(beta-expected_beta),[],1);
   intercept_error=abs(intercept(:)'-expected_intercept);
   assert(numel(coef_error)==n && numel(intercept_error)==n);
   source.coefficient_abs_differences_per_fold=coef_error(:)';
   source.intercept_abs_differences_per_fold=intercept_error(:)';
   row.max_coefficient_difference=max(coef_error);
   row.max_intercept_difference=max(intercept_error);
   failed=(coef_error>manifest.strict_full_coefficient_abs_tolerance) | ...
       (intercept_error>manifest.strict_intercept_abs_tolerance);
   row.failed_coefficient_folds_zero_based=find(failed)-1;
   row.coefficient_fold_pass_count=n-nnz(failed);
   row.max_prediction_difference=strict_vector_error(prediction,expected.predictions);
   row.max_pca_loading_difference=0;
   row.max_pca_target_difference=0;
   if imethod==2
    row.max_pca_target_difference=strict_vector_error(latent,expected.observed_fold_components);
    for k=1:n
     row.max_pca_loading_difference=max(row.max_pca_loading_difference,...
       strict_vector_error(loadings(k,:),expected.folds(k).loading));
    end
   end
   if row.coefficient_fold_pass_count==n && ...
      row.max_prediction_difference<=manifest.original_prediction_abs_tolerance && ...
      row.max_pca_loading_difference<=manifest.original_pca_quantity_abs_tolerance && ...
      row.max_pca_target_difference<=manifest.original_pca_quantity_abs_tolerance
    row.status='PASS';
   end
  catch ME
   row.error=[ME.identifier,' ',ME.message];
   source.error=row.error;
  end
  source.checked_status=row.status;
  source.max_coefficient_difference=row.max_coefficient_difference;
  source.max_intercept_difference=row.max_intercept_difference;
  source.max_prediction_difference=row.max_prediction_difference;
  source.failed_coefficient_folds_zero_based=row.failed_coefficient_folds_zero_based;
  source.max_pca_loading_difference=row.max_pca_loading_difference;
  source.max_pca_target_difference=row.max_pca_target_difference;
  write_json(fullfile(caseout,['matlab-',mode,'.json']),source);
  if isempty(records);records=row;else;records(end+1)=row;end %#ok<AGROW>
  total_folds=total_folds+n;
  coefficient_folds_pass=coefficient_folds_pass+row.coefficient_fold_pass_count;
  fprintf('GENUINE_R2026B_PROSPECTIVE_COEFF %s/%s %s coeff_folds=%d/%d coeff_max=%.17g intercept_max=%.17g pred_max=%.17g\n',...
    name,mode,row.status,row.coefficient_fold_pass_count,n,...
    row.max_coefficient_difference,row.max_intercept_difference,row.max_prediction_difference);
  if ~strcmp(row.status,'PASS');all_pass=false;end
 end
end
summary=struct('runtime','MathWorks MATLAB','release',version('-release'),...
 'statistics_toolbox',toolbox.Version,'source_revision',...
 'b903f83b476b745417b1f062f6777f5ffe118f1a',...
 'synthetic_only',true,'prospective_cohorts',numel(scenario_names),...
 'method_comparisons',numel(records),...
 'coefficient_fold_comparisons',total_folds,...
 'coefficient_folds_pass',coefficient_folds_pass,...
 'passed',sum(strcmp({records.status},'PASS')),...
 'failed',sum(strcmp({records.status},'FAIL')),...
 'all_pass',all_pass,'cases',records);
write_json(fullfile(outdir,'summary.json'),summary);
if ~all_pass
 error('GENUINE_MATLAB_PROSPECTIVE_COEFFICIENT_PARITY_FAILED: preserve all true original outputs');
end
fprintf('GENUINE_MATLAB_R2026B_PROSPECTIVE_FULL_COEFFICIENT_PARITY_PASS %d/%d folds %d/%d methods\n',...
 summary.coefficient_folds_pass,total_folds,summary.passed,summary.method_comparisons);
end

function err=strict_vector_error(a,b)
 a=double(a(:));b=double(b(:));
 if isempty(a)||numel(a)~=numel(b)||any(~isfinite(a))||any(~isfinite(b))
  error('Mismatch or nonfinite original-source vector');
 end
 err=max(abs(a-b));
end

function write_json(path,data)
 fid=fopen(path,'w');
 if fid<0;error('Cannot preserve MATLAB scientific source artifact');end
 fprintf(fid,'%s\n',jsonencode(data));fclose(fid);
end
