function report=probe_early_activation()
% Scientific hypothesis-development trace: locate the FIRST exact divergence
% between true MathWorks R2026b lasso MaxIter and a reconstructed active set
% for the same two archived synthetic, nonclinical near-lasso PCA folds.
if exist('OCTAVE_VERSION','builtin')~=0;error('Requires genuine MATLAB');end
root=fileparts(mfilename('fullpath'));
manifest=jsondecode(fileread(fullfile(root,'stress','manifest.json')));
assert(strcmp(version('-release'),'2026b') && ~manifest.patient_data_included);
spec=manifest.scenarios.near_lasso_101_n45.spec;
load(fullfile(root,'stress','near_lasso_101_n45','cohort.mat'),'all_mats');
load(fullfile(root,'stress','near_lasso_101_n45','pca-targets.mat'),'multi_behav');
n=size(all_mats,3);
edgemats=zeros(28,n);
for k=1:n;edgemats(:,k)=squareform(tril(all_mats(:,:,k),-1));end
report=struct('runtime','MathWorks MATLAB','release',version('-release'),...
 'toolbox',ver('stats'),'synthetic_only',true,...
 'source_revision','b903f83b476b745417b1f062f6777f5ffe118f1a',...
 'cases',struct([]));
for held=[7,45]
 train=true(n,1);train(held)=false;
 raw=edgemats(:,train)';
 [pc,~,~,~,~]=pca(multi_behav(train,:),'NumComponents',1);
 y=multi_behav(train,:)*pc(:,1);
 [~,p]=corr(raw,y);
 selected=find(p<0.05);
 assert(numel(selected)==19);
 x=raw(:,selected);
 args={'Alpha',spec.pca_alpha,'Lambda',spec.lam};
 entry=struct('scenario','near_lasso_101_n45','mode','pca',...
  'held_out_zero_based',held-1,'alpha',spec.pca_alpha,...
  'lambda',spec.lam,'selected_edges_matlab_one_based',selected(:)',...
  'maxiter_runs',struct([]));
 maxits=[85:155,160:5:245];
 for it=maxits
  lastwarn('');
  [b,fit]=lasso(x,y,args{:},'MaxIter',it,'UseCovariance',true);
  [~,warnid]=lastwarn;
  item=struct('maxiter',it,'coefficients',b(:)',...
   'intercept',fit.Intercept,'warning_id',warnid,...
   'actual_covariance',fit.UseCovariance);
  entry.maxiter_runs=[entry.maxiter_runs,item]; %#ok<AGROW>
 end
 report.cases=[report.cases,entry]; %#ok<AGROW>
 fprintf('MATLAB_EARLY_ACTIVATION_%d %d probes\n',held-1,numel(maxits));
end
dest=fullfile(root,'results','early_activation');
if ~exist(dest,'dir');mkdir(dest);end
f=fopen(fullfile(dest,'early_activation.json'),'w');
assert(f>0);
fprintf(f,'%s\n',jsonencode(report));fclose(f);
end
