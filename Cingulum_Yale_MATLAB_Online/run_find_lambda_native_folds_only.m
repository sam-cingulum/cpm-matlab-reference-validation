function report = run_find_lambda_native_folds_only()
% Stage A: genuine MATLAB crossvalind LABELS ONLY, no Yale source fitting.
% The original find_lambda.m, lasso(), corr() and all model-fitting methods
% are intentionally NEVER invoked in this preregistered first stage.
if exist('OCTAVE_VERSION','builtin')~=0, error('GENUINE_MATHWORKS_REQUIRED'); end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'find_lambda_prospective');
manifest=jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(manifest.original_yale_revision,...
    'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.release,'R2026b'));
assert(~manifest.patient_data_included && manifest.original_source_unmodified);
assert(manifest.native_matlab_crossvalind_labels_retained);
assert(numel(fieldnames(manifest.cases))==8);
dst=fullfile(root,'find_lambda_native_folds_only_results');
if ~exist(dst,'dir'),mkdir(dst);end
names=fieldnames(manifest.cases);
digestKey=matlab.lang.makeValidName('input.json');
items=struct('case_name',{},'seed',{},'n',{},'k',{},'complete_partition',{});
for i=1:numel(names)
    name=names{i};item=manifest.cases.(name);
    assert(isfield(item.sha256,digestKey));
    inp=jsondecode(fileread(fullfile(pack,name,'input.json')));
    n=numel(inp.dataset.observations);
    k=double(inp.k);seed=double(inp.seed);
    assert(n==item.spec.n && k==item.spec.k && seed==item.spec.seed);
    assert(n>k && k>=2);
    rng(seed);
    % ONLY the original source's native fold primitive is called.
    labels=double(crossvalind('Kfold',n,k));
    labels=labels(:)';
    assert(numel(labels)==n && all(labels>=1 & labels<=k));
    counts=histcounts(labels,0.5:1:(k+0.5));
    complete=all(counts>0) && max(counts)-min(counts)<=1;
    assert(complete);
    record=struct('runtime','MathWorks MATLAB',...
        'release',version('-release'),...
        'arch',computer('arch'),...
        'thread_count',maxNumCompThreads,...
        'case_name',name,'seed',seed,'n',n,'k',k,...
        'input_sha256',item.sha256.(digestKey),...
        'original_yale_revision',manifest.original_yale_revision,...
        'labels',labels,...
        'fold_counts',counts,...
        'complete_partition',complete,...
        'source_not_run',true,'model_fit_not_run',true,...
        'patient_data_included',false);
    preserve(fullfile(dst,[name '.json']),record);
    items(end+1)=struct('case_name',name,'seed',seed,'n',n,'k',k,... %#ok<AGROW>
        'complete_partition',complete);
    fprintf('GENUINE_MATLAB_FOLD_LABELS_ONLY %s n=%d k=%d complete=%d\n',...
        name,n,k,complete);
end
report=struct('runtime','MathWorks MATLAB',...
    'release',version('-release'),...
    'original_yale_revision',manifest.original_yale_revision,...
    'case_count',numel(names),...
    'source_not_run',true,...
    'model_fit_not_run',true,...
    'all_complete_partitions',true,...
    'cases',items);
preserve(fullfile(dst,'summary.json'),report);
end

function preserve(path,obj)
f=fopen(path,'w');assert(f>0);
closefile=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(obj));
end
