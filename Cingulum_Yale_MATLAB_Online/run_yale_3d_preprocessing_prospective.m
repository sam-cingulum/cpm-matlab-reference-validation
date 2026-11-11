function report = run_yale_3d_preprocessing_prospective()
% Original pinned Yale cpm_check_errors.m executes unchanged.
% Six source-invisible frozen synthetic input and real Rust output forecasts
% must be publicly SHA256-committed before this MATLAB stage.
if exist('OCTAVE_VERSION','builtin')~=0,error('GENUINE_MATHWORKS_ONLY');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
frozen=fullfile(root,'yale_3d_source_prospective');
manifest=jsondecode(fileread(fullfile(frozen,'manifest.json')));
assert(strcmp(manifest.experiment_id,'yale-cpm-3d-original-preprocessing-20261111-v1'));
assert(strcmp(manifest.original_source,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(strcmp(manifest.matlab_release,'R2026b'));
assert(manifest.strict_full_output_hex_equal && manifest.synthetic_only);
assert(manifest.source_fitting_not_executed_before_freeze);
names=fieldnames(manifest.cases);
assert(numel(names)==6);
addpath(fullfile(root,'upstream','yale-cpm','matlab','func'));
assert(~isempty(which('cpm_check_errors')));
outdir=fullfile(root,'yale_3d_original_results');
if ~exist(outdir,'dir'),mkdir(outdir);end
inputKey=matlab.lang.makeValidName('matlab_input.json');
rustKey=matlab.lang.makeValidName('rust_source.json');
items=struct('case_name',{},'feature_count',{},'subject_count',{},...
             'first_subject_symmetric',{});
for ci=1:numel(names)
    name=names{ci};
    metadata=manifest.cases.(name);
    assert(isfield(metadata.sha256,inputKey) && isfield(metadata.sha256,rustKey));
    payload=jsondecode(fileread(fullfile(frozen,name,'matlab_input.json')));
    assert(strcmp(payload.case_name,name));
    subjects=payload.subjects;
    n=double(payload.nsubjects);
    rows=double(payload.nrows);
    cols=double(payload.ncols);
    assert(n==metadata.subject_count && rows==metadata.rows && cols==metadata.cols);
    assert(numel(subjects)==n);
    threeD=zeros(rows,cols,n);
    for j=1:n
        mat=double(subjects(j).matrix);
        assert(isequal(size(mat),[rows,cols]));
        assert(all(isfinite(mat),'all'));
        threeD(:,:,j)=mat;
    end
    firstSym=logical(issymmetric(threeD(:,:,1)));
    assert(firstSym==metadata.first_subject_symmetric);
    y=(1:n)';
    % ORIGINAL PINNED YALE cpm_check_errors (not a transcription).
    [flat,y2]=cpm_check_errors(threeD,y,2);
    assert(isequal(y2,y));
    assert(size(flat,2)==n && all(isfinite(flat),'all'));
    nfeatures=size(flat,1);
    expected=rows*cols;
    if firstSym
        expected=rows*(rows-1)/2;
    end
    assert(nfeatures==expected);
    binary64=cellstr(num2hex(double(flat(:))));
    assert(numel(binary64)==n*nfeatures);
    record=struct('runtime','MathWorks MATLAB',...
        'release',version('-release'),...
        'source_revision',manifest.original_source,...
        'case_name',name,...
        'source_original_function_executed',true,...
        'input_sha256',metadata.sha256.(inputKey),...
        'frozen_source_rust_sha256',metadata.sha256.(rustKey),...
        'first_subject_symmetric',firstSym,...
        'feature_count',nfeatures,...
        'subject_count',n,...
        'flat_feature_hex',{binary64(:)'},...
        'synthetic_only',true,'patient_data',false);
    persist(fullfile(outdir,[name '.json']),record);
    fprintf('YALE3D_ORIGINAL_PREPROCESSOR %s symmetric-first=%d features=%d subjects=%d\n',...
        name,firstSym,nfeatures,n);
    items(end+1)=struct('case_name',name,'feature_count',nfeatures,... %#ok<AGROW>
        'subject_count',n,'first_subject_symmetric',firstSym);
end
report=struct('runtime','MathWorks MATLAB',...
    'release',version('-release'),...
    'source_revision',manifest.original_source,...
    'case_count',numel(names),'cases',items);
persist(fullfile(outdir,'summary.json'),report);
end

function persist(path,obj)
f=fopen(path,'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(obj));
end
