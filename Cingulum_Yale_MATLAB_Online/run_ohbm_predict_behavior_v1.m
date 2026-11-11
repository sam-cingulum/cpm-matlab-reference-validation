function report = run_ohbm_predict_behavior_v1()
% Prospective source-oracle stage. Genuine MATLAB R2026b and unchanged
% original Yale OHBM predict_behavior.m, with independently reconstructed
% full LOO original-model masks, OLS coefficients and all three forecasts.
% All Rust predictions already SHA256-frozen in public Git BEFORE this run.
if exist('OCTAVE_VERSION','builtin')~=0,error('GENUINE_MATHWORKS_REQUIRED');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'ohbm_predict_v1');
manifest=jsondecode(fileread(fullfile(pack,'manifest.json')));
forecast=jsondecode(fileread(fullfile(pack,'forecast_manifest.json')));
assert(strcmp(manifest.experiment_id,'ohbm-predict-behavior-20261111-v1'));
assert(strcmp(manifest.source_commit,'708999b8bb27ae69722775c323da9f14ef6732c7'));
assert(strcmp(manifest.mathworks_release,'R2026b'));
assert(manifest.synthetic_only && manifest.original_source_not_run);
assert(strcmp(forecast.experiment_id,manifest.experiment_id));
assert(forecast.rust_forecasts_frozen_before_matlab && forecast.original_source_not_run);
names=fieldnames(manifest.cases);assert(numel(names)==9);
assert(isequal(sort(names),sort(fieldnames(forecast.cases))));
addpath(fullfile(root,'upstream','yale-ohbm'));
assert(~isempty(which('predict_behavior')));
outdir=fullfile(root,'ohbm_predict_v1_original_results');
if ~exist(outdir,'dir'),mkdir(outdir);end
outcases=struct('case_name',{},'source_self_consistent',{},'maximum_r_error',{});
for ci=1:numel(names)
    name=names{ci};spec=manifest.cases.(name);
    inp=jsondecode(fileread(fullfile(pack,name,'input.json')));
    rust=jsondecode(fileread(fullfile(pack,name,'rust_forecast.json')));
    assert(strcmp(rust.original_function,'OHBM predict_behavior.m'));
    assert(strcmp(inp.selection,rust.selection));
    n=numel(inp.outcomes);d=spec.parcels;
    assert(n==spec.n && n>=25 && d>=5 && numel(rust.folds)==n);
    assert(strcmp(inp.selection,spec.selection));
    m=double(inp.subject_matrices);
    assert(size(m,1)==n && size(m,2)==d && size(m,3)==d);
    all_mats=zeros(d,d,n);
    for s=1:n
        all_mats(:,:,s)=squeeze(m(s,:,:));
        assert(isequal(all_mats(:,:,s),all_mats(:,:,s)'));
    end
    Y=double(inp.outcomes(:));p=double(inp.p_threshold);
    assert(p==0.05 && numel(Y)==n);
    covar=double(inp.covariates);
    if strcmp(inp.selection,'pearson'),option=1;
    elseif strcmp(inp.selection,'spearman'),option=2;
    elseif strcmp(inp.selection,'partial_correlation'),option=4;
    else,error('UNSUPPORTED_SELECTION_NOT_PREREGISTERED');end
    if option==4
        assert(size(covar,1)==n && size(covar,2)==spec.covariate_columns);
    end
    % The actual unmodified original source, not copied source.
    [rpos,rneg,rcom]=predict_behavior(all_mats,Y,p,option,covar);
    assert(all(isfinite([rpos,rneg,rcom])));
    reconstructed_pos=zeros(n,1);
    reconstructed_neg=zeros(n,1);
    reconstructed_com=zeros(n,1);
    models=struct('held_out_index_zero_based',{},...
        'positive_edges_upper_zero_based',{},'negative_edges_upper_zero_based',{},...
        'positive_coefficients',{},'negative_coefficients',{},...
        'combined_coefficients',{},'prediction_positive',{},...
        'prediction_negative',{},'prediction_combined',{},...
        'prediction_hex',{});
    for leftout=1:n
        train_mats=all_mats;train_mats(:,:,leftout)=[];
        train_y=Y;train_y(leftout)=[];
        train_vec=reshape(train_mats,[],n-1);
        if option==1
            [rmat,pmat]=corr(train_vec',train_y);
        elseif option==2
            [rmat,pmat]=corr(train_vec',train_y,'type','Spearman');
        else
            ct=covar;ct(leftout,:)=[];
            [rmat,pmat]=partialcorr(train_vec',train_y,ct);
        end
        rmat=reshape(rmat,d,d);pmat=reshape(pmat,d,d);
        posmask=double(rmat>0 & pmat<p);
        negmask=double(rmat<0 & pmat<p);
        assert(isequal(posmask,posmask') && isequal(negmask,negmask'));
        coordspos=zeros(0,2);coordsneg=zeros(0,2);
        for row=1:d
            for col=row+1:d
                if posmask(row,col)>0,coordspos(end+1,:)=[row-1,col-1];end %#ok<AGROW>
                if negmask(row,col)>0,coordsneg(end+1,:)=[row-1,col-1];end %#ok<AGROW>
            end
        end
        assert(~isempty(coordspos) && ~isempty(coordsneg));
        pos=zeros(n-1,1);neg=zeros(n-1,1);
        for s=1:n-1
            pos(s)=sum(sum(train_mats(:,:,s).*posmask))/2;
            neg(s)=sum(sum(train_mats(:,:,s).*negmask))/2;
        end
        bc=regress(train_y,[pos,neg,ones(n-1,1)]);
        bp=regress(train_y,[pos,ones(n-1,1)]);
        bn=regress(train_y,[neg,ones(n-1,1)]);
        test=all_mats(:,:,leftout);
        tp=sum(sum(test.*posmask))/2;
        tn=sum(sum(test.*negmask))/2;
        pc=bc(1)*tp + bc(2)*tn + bc(3);
        pp=bp(1)*tp + bp(2);
        pn=bn(1)*tn + bn(2);
        reconstructed_pos(leftout)=pp;
        reconstructed_neg(leftout)=pn;
        reconstructed_com(leftout)=pc;
        assert(all(isfinite([pc,pp,pn])));
        models(end+1)=struct('held_out_index_zero_based',leftout-1,... %#ok<AGROW>
          'positive_edges_upper_zero_based',coordspos,...
          'negative_edges_upper_zero_based',coordsneg,...
          'positive_coefficients',double(bp(:)'),...
          'negative_coefficients',double(bn(:)'),...
          'combined_coefficients',double(bc(:)'),...
          'prediction_positive',pp,'prediction_negative',pn,...
          'prediction_combined',pc,...
          'prediction_hex',{{num2hex(pp),num2hex(pn),num2hex(pc)}});
    end
    selferr=max(abs([rpos,rneg,rcom]-...
       [corr(reconstructed_pos,Y),corr(reconstructed_neg,Y),corr(reconstructed_com,Y)]));
    selfconsistent=isfinite(selferr) && selferr<=1e-10;
    assert(selfconsistent,'UNCHANGED_OHBM_SOURCE_AND_FOLD_RECONSTRUCTION_DISAGREE');
    artifact=struct('runtime','MathWorks MATLAB','release',version('-release'),...
        'source_commit',manifest.source_commit,'case_name',name,...
        'source_function_unmodified',true,'source_self_consistent',selfconsistent,...
        'source_self_r_error',selferr,'selection',inp.selection,'subjects',n,...
        'original_source_r_positive',rpos,'original_source_r_negative',rneg,...
        'original_source_r_combined',rcom,...
        'reconstructed_predictions_positive',double(reconstructed_pos(:)'),...
        'reconstructed_predictions_negative',double(reconstructed_neg(:)'),...
        'reconstructed_predictions_combined',double(reconstructed_com(:)'),...
        'reconstructed_prediction_hex_positive',{cellstr(num2hex(reconstructed_pos(:)))},...
        'reconstructed_prediction_hex_negative',{cellstr(num2hex(reconstructed_neg(:)))},...
        'reconstructed_prediction_hex_combined',{cellstr(num2hex(reconstructed_com(:)))},...
        'source_fold_models',models,...
        'input_sha256',spec.sha256,...
        'rust_frozen_sha256',forecast.cases.(name).rust_sha256,...
        'original_source_did_not_observe_rust_forecasts',true);
    preserve(fullfile(outdir,[name '.json']),artifact);
    outcases(end+1)=struct('case_name',name,'source_self_consistent',selfconsistent,... %#ok<AGROW>
        'maximum_r_error',selferr);
    fprintf('ORIGINAL_OHBM_LOO %s n=%d option=%d source_selferr=%.3g\n',name,n,option,selferr);
end
report=struct('runtime','MathWorks MATLAB','release','2026b',...
    'source_commit',manifest.source_commit,'cases',outcases,'case_count',numel(names),...
    'original_source_unchanged',true);
preserve(fullfile(outdir,'summary.json'),report);
end

function preserve(path,obj)
f=fopen(path,'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(obj));
end
