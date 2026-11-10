function report=run_yale_family_prospective()
% Unmodified original Yale kfold_family.m + native seeded MATLAB randperm.
% Input family vectors and seeds are committed before source execution.
% The Rust assignment implementation is independently precommitted; exact
% labels will be checked post-download with the genuine native permutation.
% This does NOT establish exact replication of MATLAB randperm by Rust.
if exist('OCTAVE_VERSION','builtin')~=0
    error('MATLAB_ONLY: genuine MathWorks MATLAB required');
end
root=fileparts(mfilename('fullpath'));
pack=fullfile(root,'yale_family_prospective');
m=jsondecode(fileread(fullfile(pack,'manifest.json')));
assert(strcmp(version('-release'),'2026b'));
assert(strcmp(m.source_yale_commit,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(~m.patient_data_included && m.test_exact_fold_labels);
assert(m.reference_only_not_production_cv && m.original_matlab_rng_not_claimed_reproduced);
assert(m.original_matlab_permutation_injected_after_execution);
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
assert(~isempty(which('kfold_family')));
dest=fullfile(root,'yale_family_results');
if ~exist(dest,'dir'),mkdir(dest);end
names=fieldnames(m.cases);
entries=struct('case_name',{},'subjects',{},'families',{},'k',{}, ...
    'zero_assignments',{},'complete_partition',{});
for j=1:numel(names)
    name=names{j};
    x=jsondecode(fileread(fullfile(pack,name,'input.json')));
    fam=double(x.family_ids(:));
    seed=double(x.seed);k=double(x.k);
    n=numel(fam);
    assert(n==x.subjects);
    assert(numel(unique(fam))==x.distinct_families);
    assert(k==m.cases.(name).k);
    family_matrix=[(1:n)',fam];
    % Original source performs rng(seed), randperm(n) once. Capture that
    % exact RNG output without modifying the Yale function itself.
    rng(seed);
    permutation=randperm(n);
    ids=kfold_family(family_matrix,k,seed);
    assert(numel(ids)==n);
    assert(all(ids>=0 & ids<=k));
    for family=unique(fam)'
        assert(numel(unique(ids(fam==family)))==1);
    end
    counts=zeros(k,1);
    for fold=1:k,counts(fold)=sum(ids==fold);end
    unassigned=find(ids==0)-1;
    complete=isempty(unassigned) && all(counts>0);
    row=struct('case_name',name,'subjects',n,'families',numel(unique(fam)), ...
        'k',k,'zero_assignments',numel(unassigned),'complete_partition',complete);
    entries(end+1)=row; %#ok<AGROW>
    artifact=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
        'original_yale_source_sha',m.source_yale_commit, ...
        'case_name',name,'seed',seed,'k',k, ...
        'patient_data_included',false, ...
        'authentic_matlab_randperm_zero_based',double(permutation(:)'-1), ...
        'original_yale_fold_labels',double(ids(:)'), ...
        'original_yale_fold_sizes',double(counts(:)'), ...
        'original_unassigned_indices',double(unassigned(:)'), ...
        'original_complete_partition',complete);
    write_json(fullfile(dest,[name '.json']),artifact);
    fprintf('YALE_FAMILY_SOURCE %s n=%d k=%d unassigned=%d\n',name,n,k,numel(unassigned));
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
    'source_commit',m.source_yale_commit, ...
    'case_count',numel(entries),'cases',entries, ...
    'original_source_execution_complete',true, ...
    'not_a_claim_of_matlab_rng_parity',true, ...
    'patient_data_included',false);
write_json(fullfile(dest,'summary.json'),report);
end
function write_json(path,obj)
fid=fopen(path,'w');
if fid<0,error('Unable to preserve source evidence');end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(obj));
end
