function entry = capture_entry(root)
% Linux initial process controls and actual MATLAB argv, with no secret capture.
keys={'MKL_NUM_THREADS','OMP_NUM_THREADS','MKL_CBWR'};
expected={'1','1','COMPATIBLE'};
fid=fopen('/proc/self/environ','rb'); assert(fid>=0);
raw=char(fread(fid,Inf,'*uint8').'); fclose(fid);
parts=strsplit(raw,char(0));
initial=cell(1,3); current=cell(1,3);
for j=1:3
    prefix=[keys{j},'=']; found=parts(startsWith(parts,prefix));
    assert(numel(found)==1,'Missing or duplicate initial process control');
    initial{j}=found{1}(numel(prefix)+1:end);
    current{j}=getenv(keys{j});
end
fid=fopen('/proc/self/cmdline','rb'); assert(fid>=0);
raw=char(fread(fid,Inf,'*uint8').'); fclose(fid);
args=strsplit(raw,char(0));
flag_count=sum(strcmp(args,'-singleCompThread'));
threads=maxNumCompThreads;
fid=fopen(fullfile(root,'out','original_cpu.txt'),'a'); assert(fid>=0);
for j=1:3
    fprintf(fid,'MATLAB initial %s=%s\n',keys{j},initial{j});
    fprintf(fid,'MATLAB current %s=%s\n',keys{j},current{j});
end
fprintf(fid,'MATLAB argv -singleCompThread count=%d\n',flag_count);
fprintf(fid,'MATLAB entry maxNumCompThreads=%d\n',threads);
fclose(fid);
assert(isequal(initial,expected)&&isequal(current,expected));
assert(flag_count==1 && threads==1);
entry=struct('proc_mkl_num_threads',initial{1},'proc_omp_num_threads',initial{2}, ...
    'proc_mkl_cbwr',initial{3},'argv_single_comp_thread_count',flag_count, ...
    'run_attempt',getenv('GITHUB_RUN_ATTEMPT'),'public_ref',getenv('GITHUB_REF'), ...
    'job_key',getenv('GITHUB_JOB'),'job_os',getenv('CPM_MATRIX_OS'));
assert(~isempty(regexp(entry.run_attempt,'^[1-9][0-9]*$','once')));
assert(strcmp(entry.job_key,'original-only'));
assert(any(strcmp(entry.job_os,{'ubuntu-22.04','ubuntu-24.04'})));
end
