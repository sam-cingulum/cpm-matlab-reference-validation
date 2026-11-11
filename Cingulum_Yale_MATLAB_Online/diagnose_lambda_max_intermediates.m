function report = diagnose_lambda_max_intermediates()
% Read-only reconstruction of pinned original source arithmetic. Comparison
% with actual unmodified original function output is mandatory and exact.
% Diagnostic values are NOT claims about MathWorks internal BLAS reduction.
if exist('OCTAVE_VERSION','builtin')~=0,error('MATLAB_REQUIRED');end
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
fixtures=fullfile(root,'lambda_max_prospective');
manifest=jsondecode(fileread(fullfile(fixtures,'manifest.json')));
assert(strcmp(manifest.original_yale_sha,'b903f83b476b745417b1f062f6777f5ffe118f1a'));
addpath(fullfile(root,'upstream','yale-cpm','matlab','misc'));
names={'weighted_extreme','weighted_normalized','weighted_nonunit','weighted_sparse'};
outdir=fullfile(root,'lambda_max_intermediate_results');
if ~exist(outdir,'dir'),mkdir(outdir);end
records=struct('name',{},'source_lambda',{},'source_mse',{}, ...
    'reconstructed_lambda',{},'reconstructed_mse',{},'weight_sum',{}, ...
    'mu_y',{},'mu_y_hex',{},'sigma_x_hex',{},'mu_x_hex',{}, ...
    'per_feature_abs_dot',{},'weighted_centered_residual',{},'diagnostic_matches_source',{});
for i=1:numel(names)
    name=names{i};
    input=jsondecode(fileread(fullfile(fixtures,name,'input.json')));
    X=double(input.x); Y=double(input.y(:)); w=double(input.weights(:));
    a=double(input.alpha);st=logical(input.standardize);
    [lam,mse]=computeLambdaMax(X,Y,w,a,st);
    nw=w/sum(w);
    muX=nw'*X;
    X0=bsxfun(@minus,X,muX);
    if st
        sigmaX=sqrt(nw'*(X0.^2));
        sigmaX(range(X)==0)=1;
        X0=bsxfun(@rdivide,X0,sigmaX);
    else
        sigmaX=ones(1,size(X,2));
    end
    muY=w'*Y;
    Y0=Y-muY;
    dotp=abs(sum(bsxfun(@times,bsxfun(@times,X0,w),Y0)));
    lam2=max(dotp)/a;
    mse2=w'*(Y0.^2);
    % Hex of exact IEEE 754 binary64 intermediate representations.
    record=struct('name',name,'source_lambda',lam,'source_mse',mse, ...
        'reconstructed_lambda',lam2,'reconstructed_mse',mse2, ...
        'weight_sum',sum(w),'mu_y',muY,'mu_y_hex',num2hex(muY), ...
        'sigma_x_hex',{cellstr(num2hex(sigmaX(:)))}, ...
        'mu_x_hex',{cellstr(num2hex(muX(:)))}, ...
        'per_feature_abs_dot',dotp,'weighted_centered_residual',mse2, ...
        'diagnostic_matches_source',isequal(lam,lam2)&&isequal(mse,mse2));
    records(end+1)=record; %#ok<AGROW>
    f=fopen(fullfile(outdir,[name '.json']),'w');assert(f>0);
    fprintf(f,'%s\n',jsonencode(record));fclose(f);
    fprintf('MATLAB_INTERMEDIATE %s lambda_equal=%d mse_equal=%d muY=%s\n', ...
        name,isequal(lam,lam2),isequal(mse,mse2),num2hex(muY));
end
report=struct('runtime','MathWorks MATLAB','release',version('-release'), ...
    'pinned_source',manifest.original_yale_sha,'records',records);
f=fopen(fullfile(outdir,'summary.json'),'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(report));fclose(f);
end
