function matlab_r2026b_builtin_source_architecture_discovery_v1
% SOURCE INSPECTION ONLY: NO NUMERIC PARITY CERTIFICATE, NOT V12.
% Observe built-in / M-code status and licensing, do not copy vendor code.
assert(strcmp(version('-release'),'2026b'),'Requires genuine R2026b');
fprintf('CLASSIFICATION=MATLAB_R2026B_BUILTIN_SOURCE_ARCHITECTURE_METADATA_ONLY\n');
fprintf('RELEASE=%s\n', version('-release'));
fprintf('ARCH=%s\n', computer);
labels = {'betainc','tcdf','gammaln','betaln','gamma','codegen','coder.config'};
for k=1:numel(labels)
    label=labels{k};
    try
        method=which(label);
        if isempty(method), method='NOT_FOUND'; end
        fprintf('FUNCTION=%s CLASS=%s BUILTIN=%d FILE=%d RESOLUTION=%s\n',...
           label,class(method),exist(label,'builtin'),exist(label,'file'),method);
    catch ME
        fprintf('FUNCTION=%s METADATA_ERROR=%s\n',label,ME.identifier);
    end
end
try
    fprintf('MATLAB_CODER_LICENSE_TEST=%d\n',license('test','MATLAB_Coder'));
catch ME
    fprintf('MATLAB_CODER_LICENSE_ERROR=%s\n',ME.identifier);
end
try
    fprintf('STATS_LICENSE_TEST=%d\n',license('test','Statistics_Toolbox'));
catch ME
    fprintf('STATS_LICENSE_ERROR=%s\n',ME.identifier);
end
fprintf('END_SOURCE_ARCHITECTURE_METADATA_ONLY\n');
end
