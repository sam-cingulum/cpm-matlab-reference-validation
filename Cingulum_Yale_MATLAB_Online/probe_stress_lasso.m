function report = probe_stress_lasso()
% Direct genuine MathWorks R2026b solver diagnostics on independent synthetic
% original-source stress inputs; NEVER substitutes modified Yale functions.
if exist('OCTAVE_VERSION','builtin')~=0;error('Genuine MATLAB only');end
root=fileparts(mfilename('fullpath'));
manifest=jsondecode(fileread(fullfile(root,'stress','manifest.json')));
assert(~manifest.patient_data_included);
assert(strcmp(version('-release'),'2026b'));
selected_scenarios={'seed_41_n33','seed_73_n61','near_lasso_101_n45',...
 'high_penalty_211_n52','outlier_567_n39','degenerate_929_n53'};
% Dense early-iteration diagnostics distinguish repeated active-set sweeps from
% full-feature sweeps; preserve the original widely spaced checkpoints.
maxits=[1:20,25,30,35,40,45,50,60,70,80,100,120,150,180,210,240,274:280,300,350,435:438,450:455];
report=struct('runtime','MathWorks MATLAB','release',version('-release'),...
 'toolbox',ver('stats'),'source_revision',...
 'b903f83b476b745417b1f062f6777f5ffe118f1a',...
 'synthetic_only',true,'cases',struct([]));
for is=1:numel(selected_scenarios)
 scenario=selected_scenarios{is};
 spec=manifest.scenarios.(scenario).spec;
 path=fullfile(root,'stress',scenario);
 load(fullfile(path,'cohort.mat'),'all_mats','all_behav');
 load(fullfile(path,'pca-targets.mat'),'multi_behav');
 N=size(all_mats,3);
 E=size(all_mats,1)*(size(all_mats,1)-1)/2;
 edgemats=zeros(E,N);
 for k=1:N
  edgemats(:,k)=squareform(tril(all_mats(:,:,k),-1));
 end
 % Extend the immutable synthetic-only battery to previously unmatched folds.
% MATLAB row indices here are one-based; the archived failures are zero-based.
if strcmp(scenario,'seed_73_n61')
 helds=[1,45];
elseif strcmp(scenario,'near_lasso_101_n45')
 helds=[1,7,15,23,36,45];
elseif strcmp(scenario,'outlier_567_n39')
 helds=[1,16,20,24,26];
else
 helds=[1,round(N/2)];
end
 for modeid=1:2
  if modeid==1
   mode='ridge';alpha=spec.ridge_alpha;
  else
   mode='pca';alpha=spec.pca_alpha;
  end
  for held=helds
   train=true(N,1);train(held)=false;
   X=edgemats(:,train)';
   if modeid==1
    y=all_behav(train);
   else
    [pc,~,~,~,~]=pca(multi_behav(train,:),'NumComponents',1);
    y=multi_behav(train,:)*pc(:,1);
   end
   [~,pvalues]=corr(X,y);
   if modeid==1
    eligible=find(pvalues<=0.05);
   else
    eligible=find(pvalues<0.05);
   end
   assert(~isempty(eligible));
   X=X(:,eligible);
   args={'Alpha',alpha,'Lambda',spec.lam};
   [beta,fit]=lasso(X,y,args{:});
   row=struct('scenario',scenario,'method',mode,'held_out_zero_based',held-1,...
    'alpha',alpha,'lambda',spec.lam,'num_training',sum(train),...
    'selected_edges_matlab_one_based',eligible(:)',...
    'default_coefficients',beta(:)',...
    'default_intercept',fit.Intercept,'default_use_covariance',fit.UseCovariance,...
    'maxiter_runs',struct([]),'covariance_runs',struct([]),...
    'tolerance_runs',struct([]));
   for ncov=1:2
    usecov=(ncov==2);
    [v,fi]=lasso(X,y,args{:},'UseCovariance',usecov);
    item=struct('covariance_requested',usecov,'use_covariance_actual',fi.UseCovariance,...
     'coefficients',v(:)','intercept',fi.Intercept);
    row.covariance_runs=[row.covariance_runs,item]; %#ok<AGROW>
   end
   for ntol=[1e-3,1e-4,1e-5,1e-7]
    [v,fi]=lasso(X,y,args{:},'RelTol',ntol);
    item=struct('relative_tolerance',ntol,'coefficients',v(:)',...
     'intercept',fi.Intercept,'covariance_actual',fi.UseCovariance);
    row.tolerance_runs=[row.tolerance_runs,item]; %#ok<AGROW>
   end
   for ni=1:numel(maxits)
    lastwarn('');
    [v,fi]=lasso(X,y,args{:},'MaxIter',maxits(ni));
    [msg,wid]=lastwarn;
    item=struct('maxiter',maxits(ni),'coefficients',v(:)',...
     'intercept',fi.Intercept,'warning_id',wid,'warning_message',msg,...
     'covariance_actual',fi.UseCovariance);
    row.maxiter_runs=[row.maxiter_runs,item]; %#ok<AGROW>
   end
   report.cases=[report.cases,row]; %#ok<AGROW>
   fprintf('SOLVER_PROBE %s/%s held %d edges %d cov %d\n',...
    scenario,mode,held-1,numel(eligible),fit.UseCovariance);
  end
 end
end
assert(numel(report.cases)==38); % Existing 24 plus 14 targeted method/fold probes.
dest=fullfile(root,'results','stress_probes');
if ~exist(dest,'dir');mkdir(dest);end
out=fopen(fullfile(dest,'solver_probes.json'),'w');
if out<0;error('Unable to persist R2026b authentic solver probes');end
fprintf(out,'%s\n',jsonencode(report));
fclose(out);
fprintf('SCIENTIFIC AUTHENTIC MATLAB SOLVER PROBES completed %d cases\n',numel(report.cases));
end
