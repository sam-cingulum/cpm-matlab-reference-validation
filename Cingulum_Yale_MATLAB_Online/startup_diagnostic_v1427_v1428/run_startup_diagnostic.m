function run_startup_diagnostic()
% Startup diagnostic only. No holdout input, candidate or numerical comparison.
root=fileparts(mfilename('fullpath'));
log=fullfile(root,'out','entry_stages.txt');
mark(log,'MATLAB function entered');
try
    mark(log,['version=',version]);
    assert(exist('OCTAVE_VERSION','builtin')==0);
    assert(strcmp(version,'26.2.0.3433840 (R2026b) Update 1'));
    mark(log,'version qualified');
    mark(log,sprintf('initial maxNumCompThreads=%d',maxNumCompThreads));
    keys={'MKL_NUM_THREADS','OMP_NUM_THREADS','MKL_CBWR'};
    for i=1:numel(keys)
        mark(log,[keys{i},'=',getenv(keys{i})]);
    end
    mark(log,'before capture_entry');
    capture_entry(root);
    mark(log,'capture_entry qualified');
    mark(log,'STARTUP_DIAGNOSTIC_PASS');
catch ME
    mark(log,['error identifier=',ME.identifier]);
    mark(log,['error message=',ME.message]);
    rethrow(ME);
end
end

function mark(log,message)
fid=fopen(log,'a'); assert(fid>=0);
fprintf(fid,'%s\n',message); fclose(fid);
fprintf(1,'%s\n',message);
end
