function result = probe_lasso_thresholds()
% Genuine MathWorks MATLAB R2026b synthetic-only RelTol stopping-boundary audit.
% Yale's original functions remain unchanged; no private model or clinical data.
% For each selected fold, isolate the interval of RelTol values returning
% *exactly* the archived default MATLAB coefficient vector.
if exist('OCTAVE_VERSION','builtin') ~= 0
    error('This proof requires genuine MathWorks MATLAB');
end
root = fileparts(mfilename('fullpath'));
scenarios = {'baseline','rescaled','severe_outlier'};
helds = [1,24,48];
maxsteps = 20;
tol0 = 1e-4;
result = struct('runtime','MathWorks MATLAB','release',version('-release'),...
    'statistics_version',ver('stats'),'synthetic_only',true,...
    'source_commit','b903f83b476b745417b1f062f6777f5ffe118f1a',...
    'purpose','Map exact RelTol boundaries of genuine lasso returned coordinate trajectory',...
    'tolerance',tol0,'binary_search_steps',maxsteps,'cases',struct([]));
for sc = 1:numel(scenarios)
    scenario = scenarios{sc};
    fixture = fullfile(root,'fixtures',scenario);
    load(fullfile(fixture,'cohort.mat'),'all_mats','all_behav');
    load(fullfile(fixture,'pca-targets.mat'),'multi_behav');
    n = size(all_mats,3);
    assert(n >= max(helds));
    p = size(all_mats,1);
    edges = zeros(p*(p-1)/2,n);
    for i = 1:n
        edges(:,i)=squareform(tril(all_mats(:,:,i),-1));
    end
    for method_num = 1:2
        if method_num == 1
            method = 'ridge-compat';
            alpha = 1e-9;
        else
            method = 'pca';
            alpha = 1e-6;
        end
        for held=helds
            train=true(n,1);train(held)=false;
            X=edges(:,train)';
            if method_num == 1
                y=all_behav(train);
            else
                [weights,~,~,~,~]=pca(multi_behav(train,:),'NumComponents',1);
                y=multi_behav(train,:)*weights(:,1);
            end
            [~,edge_p]=corr(X,y);
            if method_num == 1
                selected=find(edge_p<=0.05);
            else
                selected=find(edge_p<0.05);
            end
            assert(numel(selected)>0);
            X=X(:,selected);
            options={'Alpha',alpha,'Lambda',0.1,'UseCovariance',true};
            reference=lasso(X,y,options{:},'RelTol',tol0);
            hi_same=tol0;hi_other=tol0*1.2;
            for tryidx=1:16
                if same_fit(X,y,options,hi_other,reference)
                    hi_same=hi_other;
                    hi_other=hi_other*1.4;
                else
                    break;
                end
            end
            assert(~same_fit(X,y,options,hi_other,reference), ...
                'Failed to bracket earlier convergence threshold');
            lo_same=tol0;lo_other=tol0/1.2;
            for tryidx=1:16
                if same_fit(X,y,options,lo_other,reference)
                    lo_same=lo_other;
                    lo_other=lo_other/1.4;
                else
                    break;
                end
            end
            assert(~same_fit(X,y,options,lo_other,reference), ...
                'Failed to bracket later convergence threshold');
            for iteration=1:maxsteps
                trial=(hi_same+hi_other)/2;
                if same_fit(X,y,options,trial,reference)
                    hi_same=trial;
                else
                    hi_other=trial;
                end
                trial=(lo_same+lo_other)/2;
                if same_fit(X,y,options,trial,reference)
                    lo_same=trial;
                else
                    lo_other=trial;
                end
            end
            case_row=struct();
            case_row.scenario=scenario;
            case_row.method=method;
            case_row.held_out_zero_based=held-1;
            case_row.selected_edges_one_based=selected(:)';
            case_row.alpha=alpha;
            case_row.lambda=0.1;
            case_row.default_coefficients=reference(:)';
            case_row.lowest_same_reltol=lo_same;
            case_row.later_fit_reltol=lo_other;
            case_row.highest_same_reltol=hi_same;
            case_row.earlier_fit_reltol=hi_other;
            case_row.lower_boundary_width=lo_same-lo_other;
            case_row.upper_boundary_width=hi_other-hi_same;
            result.cases=[result.cases,case_row]; %#ok<AGROW>
            fprintf('THRESHOLD %s %s held=%d lower=[%.12g %.12g] upper=[%.12g %.12g]\n', ...
                scenario,method,held-1,lo_other,lo_same,hi_same,hi_other);
        end
    end
end
assert(numel(result.cases)==numel(scenarios)*2*numel(helds));
dest=fullfile(root,'results','diagnostics');
if ~exist(dest,'dir');mkdir(dest);end
fh=fopen(fullfile(dest,'stopping_thresholds.json'),'w');
if fh<0;error('Cannot write threshold JSON');end
fprintf(fh,'%s\n',jsonencode(result));
fclose(fh);
fprintf('Authentic MATLAB stopping threshold boundaries saved for %d synthetic folds\n',numel(result.cases));
end

function same=same_fit(X,y,options,tolerance,expected)
    fit=lasso(X,y,options{:},'RelTol',tolerance);
    same=max(abs(fit(:)-expected(:)))<1e-12;
end
