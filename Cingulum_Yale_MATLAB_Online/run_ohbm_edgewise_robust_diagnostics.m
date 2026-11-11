function report = run_ohbm_edgewise_robust_diagnostics()
% Exploratory MathWorks R2026b robustfit t-statistic diagnostic on
% ALREADY PUBLIC, ALREADY EXPOSED synthetic OHBM case inputs.
% This is not prospective parity, and it is NOT a certification.
if exist('OCTAVE_VERSION','builtin')~=0,error('GENUINE_MATHWORKS_REQUIRED');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'ohbm_predict_v1');
manifest=jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(manifest.source_commit,'708999b8bb27ae69722775c323da9f14ef6732c7'));
cases={'ohbm_pearson_normal_n31_s171801',...
 'ohbm_spearman_ties_n39_s171833',...
 'ohbm_partial_correlation_outliers_n39_s171851'};
outdir=fullfile(root,'ohbm_edgewise_robust_diagnostics');
if ~exist(outdir,'dir'),mkdir(outdir);end
records=struct('case_name',{},'fit_count',{},'first_fold_t_hex',{});
for ci=1:numel(cases)
    name=cases{ci};
    inp=jsondecode(fileread(fullfile(pack,name,'input.json')));
    mats=double(inp.subject_matrices);
    n=numel(inp.outcomes);d=size(mats,2);y=double(inp.outcomes(:));
    allmats=zeros(d,d,n);
    for s=1:n, allmats(:,:,s)=squeeze(mats(s,:,:));end
    aa=triu(ones(d,d),1);
    upper=find(aa);
    edges=struct('leftout_zero_based',{},'row_zero_based',{},'col_zero_based',{},...
       't',{},'t_hex',{},'se',{},'se_hex',{},'b',{},...
       'robust_scale',{},'mad_scale',{},'ols_scale',{},...
       'full_stats',{},'provenance',{});
    count=0;
    folds=unique([1,ceil(n/2),n]);
    for leftout=folds
        training=allmats;training(:,:,leftout)=[];
        vect=reshape(training,[],n-1);
        train_y=y;train_y(leftout)=[];
        for e=1:numel(upper)
            x=vect(upper(e),:)';
            [b,stats]=robustfit(x,train_y);
            [row,col]=ind2sub([d,d],upper(e));
            entry=struct('leftout_zero_based',leftout-1,...
               'row_zero_based',row-1,'col_zero_based',col-1,...
               't',stats.t(2),'t_hex',num2hex(stats.t(2)),...
               'se',stats.se(2),'se_hex',num2hex(stats.se(2)),...
               'b',double(b(:)'),...
               'robust_scale',stats.robust_s,...
               'mad_scale',stats.mad_s,...
               'ols_scale',stats.ols_s,...
               'full_stats',stats,...
               'provenance','direct original MathWorks robustfit stats, unmodified');
            edges(end+1)=entry; %#ok<AGROW>
            count=count+1;
        end
    end
    artifact=struct('runtime','MathWorks MATLAB','release','2026b',...
       'experimental_status','POSTHOC_DIAGNOSTIC_NOT_PROSPECTIVE_PARITY',...
       'source_commit',manifest.source_commit,'case_name',name,...
       'input_sha256',manifest.cases.(name).sha256,...
       'matlab_arch',computer('arch'),...
       'folds_zero_based',double(folds-1),...
       'full_edge_robustfits',edges,'count',count);
    preserve(fullfile(outdir,[name '.json']),artifact);
    records(end+1)=struct('case_name',name,'fit_count',count,... %#ok<AGROW>
        'first_fold_t_hex',edges(1).t_hex);
    fprintf('EDGEWISE_ROBUSTFIT_DIAGNOSTIC %s fits=%d\n',name,count);
end
report=struct('runtime','MathWorks MATLAB','release','2026b',...
    'not_prospective_certification',true,'cases',records);
preserve(fullfile(outdir,'summary.json'),report);
end
function preserve(path,obj)
f=fopen(path,'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(obj));
end
