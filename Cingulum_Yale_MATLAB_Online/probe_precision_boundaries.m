function report = probe_precision_boundaries()
% Authentic MathWorks R2026b post-hoc diagnosis of two non-identical
% coefficient vectors in the historical synthetic near-lasso PCA stress case.
% This is exploratory evidence; it is NOT an independent prospective gate.
if exist('OCTAVE_VERSION','builtin')~=0;error('Genuine MATLAB only');end
root=fileparts(mfilename('fullpath'));
manifest=jsondecode(fileread(fullfile(root,'stress','manifest.json')));
assert(~manifest.patient_data_included);
assert(strcmp(version('-release'),'2026b'));
assert(strcmp(manifest.source_commit.yale_cpm,...
    'b903f83b476b745417b1f062f6777f5ffe118f1a'));
spec=manifest.scenarios.near_lasso_101_n45.spec;
load(fullfile(root,'stress','near_lasso_101_n45','cohort.mat'),'all_mats','all_behav');
load(fullfile(root,'stress','near_lasso_101_n45','pca-targets.mat'),'multi_behav');
n=size(all_mats,3);
edgemats=zeros(28,n);
for k=1:n
 edgemats(:,k)=squareform(tril(all_mats(:,:,k),-1));
end
maxits=[450,650,800,900,950,970,975,980,982,984,985:995,998:1006,1010,1020];
report=struct('runtime','MathWorks MATLAB','release',version('-release'),...
 'toolbox',ver('stats'),'source_revision',...
 'b903f83b476b745417b1f062f6777f5ffe118f1a',...
 'synthetic_only',true,'probes',struct([]));
for held=[7,45] % MATLAB 1-based; private audit used zero-based 6,44.
 train=true(n,1);train(held)=false;
 x=edgemats(:,train)';
 [pc,~,~,~,~]=pca(multi_behav(train,:),'NumComponents',1);
 y=multi_behav(train,:)*pc(:,1);
 [~,pvalues]=corr(x,y);
 eligible=find(pvalues<0.05);
 assert(numel(eligible)==19);
 x=x(:,eligible);
 args={'Alpha',spec.pca_alpha,'Lambda',spec.lam};
 [default_coeffs,default_fit]=lasso(x,y,args{:});
 row=struct('scenario','near_lasso_101_n45','method','pca',...
  'held_out_zero_based',held-1,'selected_edges_matlab_one_based',eligible(:)',...
  'alpha',spec.pca_alpha,'lambda',spec.lam,...
  'default_coefficients',default_coeffs(:)',...
  'default_intercept',default_fit.Intercept,...
  'default_use_covariance',default_fit.UseCovariance,...
  'maxiter_runs',struct([]),'variant_runs',struct([]));
 for i=1:numel(maxits)
  lastwarn('');
  [v,fit]=lasso(x,y,args{:},'MaxIter',maxits(i));
  [~,warning_id]=lastwarn;
  item=struct('maxiter',maxits(i),'coefficients',v(:)',...
   'intercept',fit.Intercept,'warning_id',warning_id,...
   'actual_covariance',fit.UseCovariance);
  row.maxiter_runs=[row.maxiter_runs,item]; %#ok<AGROW>
 end
 for covariance=[false,true]
  for tolerance=[1e-4,9.9999999e-5,1.00000001e-4,9.9e-5,9e-5,8e-5,1.1e-4,1e-5]
   lastwarn('');
   [v,fit]=lasso(x,y,args{:},'UseCovariance',covariance,'RelTol',tolerance);
   [~,warning_id]=lastwarn;
   item=struct('use_covariance_requested',covariance,...
    'use_covariance_actual',fit.UseCovariance,...
    'relative_tolerance',tolerance,'coefficients',v(:)',...
    'intercept',fit.Intercept,'warning_id',warning_id);
   row.variant_runs=[row.variant_runs,item]; %#ok<AGROW>
  end
 end
 report.probes=[report.probes,row]; %#ok<AGROW>
 fprintf('PRECISION_PROBE near_lasso pca held=%d default_cov=%d maxits=%d variants=%d\n',...
  held-1,default_fit.UseCovariance,numel(row.maxiter_runs),numel(row.variant_runs));
end
assert(numel(report.probes)==2);
dest=fullfile(root,'results','precision_boundaries');
if ~exist(dest,'dir');mkdir(dest);end
fid=fopen(fullfile(dest,'precision_boundaries.json'),'w');
if fid<0;error('Cannot save precision probe');end
fprintf(fid,'%s\n',jsonencode(report));
fclose(fid);
fprintf('MATLAB_PRECISION_DIAGNOSTICS_COMPLETE %d cases\n',numel(report.probes));
end
