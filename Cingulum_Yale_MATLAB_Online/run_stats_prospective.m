function summary = run_stats_prospective()
% Original pinned Yale fdr_bh.m / bonf_holm.m, genuine MATLAB R2026b only.
% Independent Rust forecasts and SHA256s are frozen BEFORE this runner starts.
% The original Yale source is checked out unmodified by official CI.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('MATLAB_ONLY: Genuine MathWorks MATLAB required');
end
root=fileparts(mfilename('fullpath'));
inputDir=fullfile(root,'stats_prospective');
manifest=jsondecode(fileread(fullfile(inputDir,'manifest.json')));
assert(~manifest.patient_data_included);
assert(strcmp(manifest.original_upstream_yale_commit,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
assert(manifest.source_comparison_absolute_tolerance==1e-12);
assert(manifest.require_exact_rejection_decision && manifest.require_exact_shape);
assert(strcmp(version('-release'),'2026b'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','oop'));
assert(~isempty(which('fdr_bh')) && ~isempty(which('bonf_holm')));
toolbox=ver('stats');
assert(~isempty(toolbox));
dst=fullfile(root,'stats_results');
if ~exist(dst,'dir'),mkdir(dst);end
names=fieldnames(manifest.cases);
profiles={'yale-fdr-pdep','yale-fdr-dep','yale-holm-source'};
items=struct('scenario',{},'profile',{},'elements',{},'pass',{}, ...
    'max_abs_adjusted_p_error',{},'max_abs_critical_p_error',{}, ...
    'max_abs_ci_coverage_error',{},'decision_mismatches',{});
allpass=true;
for ci=1:numel(names)
    name=names{ci};
    folder=fullfile(inputDir,name);
    spec=jsondecode(fileread(fullfile(folder,'spec.json')));
    pvalues=double(jsondecode(fileread(fullfile(folder,'pvalues.json'))));
    pvalues=pvalues(:);
    shape=double(spec.shape(:)');
    assert(numel(pvalues)==prod(shape));
    pvalues=reshape(pvalues,shape);
    for pi=1:numel(profiles)
        profile=profiles{pi};
        rust=jsondecode(fileread(fullfile(folder,['rust-' profile '.json'])));
        assert(numel(rust.adjusted_p_values)==numel(pvalues));
        alpha=spec.alpha;
        if strcmp(profile,'yale-holm-source')
            [adjusted,decision]=bonf_holm(pvalues,alpha);
            critical=[]; coverage=[];
        else
            method='pdep';
            if strcmp(profile,'yale-fdr-dep'),method='dep';end
            [decision,critical,coverage,adjusted]=fdr_bh(pvalues,alpha,method,'no');
        end
        assert(isequal(size(adjusted),size(pvalues)));
        assert(isequal(size(decision),size(pvalues)));
        expected_decision=logical(rust.rejected(:));
        actual_decision=logical(decision(:));
        decision_errors=sum(expected_decision~=actual_decision);
        coeff_error=max(abs(double(adjusted(:))-double(rust.adjusted_p_values(:))));
        critical_error=0;
        coverage_error=0;
        if ~isempty(critical)
            assert(~isempty(rust.critical_p));
            critical_error=abs(double(critical)-double(rust.critical_p));
        elseif strcmp(profile,'yale-holm-source')
            assert(isempty(rust.critical_p));
        end
        if ~isempty(coverage) && isfinite(coverage)
            assert(~isempty(rust.adjusted_ci_coverage));
            coverage_error=abs(double(coverage)-double(rust.adjusted_ci_coverage));
        elseif ~isempty(coverage)
            assert(isnan(coverage) && isempty(rust.adjusted_ci_coverage));
        end
        passed=decision_errors==0 && ...
            all(isfinite(adjusted(:))) && ...
            isfinite(coeff_error) && coeff_error<=manifest.source_comparison_absolute_tolerance && ...
            isfinite(critical_error) && critical_error<=manifest.source_comparison_absolute_tolerance && ...
            isfinite(coverage_error) && coverage_error<=manifest.source_comparison_absolute_tolerance;
        row=struct('scenario',name,'profile',profile,'elements',numel(pvalues), ...
            'pass',passed,'max_abs_adjusted_p_error',coeff_error, ...
            'max_abs_critical_p_error',critical_error, ...
            'max_abs_ci_coverage_error',coverage_error, ...
            'decision_mismatches',decision_errors);
        items(end+1)=row; %#ok<AGROW>
        allpass=allpass && passed;
        raw=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
            'toolbox_version',toolbox.Version, ...
            'source_commit',manifest.original_upstream_yale_commit, ...
            'scenario',name,'profile',profile,'alpha',alpha, ...
            'input_shape',shape,'pvalues_original_linear_order',pvalues(:)', ...
            'adjusted_p_values',double(adjusted(:)'), ...
            'rejected',logical(decision(:)'), ...
            'critical_p',critical,'adjusted_ci_coverage',coverage, ...
            'comparison',row,'patient_data_included',false);
        write_json(fullfile(dst,[name '__' profile '.json']),raw);
        fprintf('STATS ORIGINAL YALE: %s/%s %s max %.5g decisions wrong %d\n', ...
            name,profile,string(passed),coeff_error,decision_errors);
    end
end
summary=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
    'toolbox_version',toolbox.Version,'original_yale_sha',manifest.original_upstream_yale_commit, ...
    'data_type','synthetic_only','cases',items, ...
    'comparisons',numel(items),'all_pass',allpass, ...
    'decision_mismatches',sum([items.decision_mismatches]));
write_json(fullfile(dst,'summary.json'),summary);
if ~allpass
    error('GENUINE_MATLAB_PINNED_YALE_MULTITEST_STRICT_PARITY_FAILED');
end
end
function write_json(path,value)
fid=fopen(path,'w');
if fid<0,error('Unable to write original-source evidence');end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(value));
end
