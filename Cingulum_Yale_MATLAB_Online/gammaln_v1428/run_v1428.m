function run_v1428()
% Original scalar gammaln acquisition, with no native predictions available.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version,'26.2.0.3433840 (R2026b) Update 1'));
assert(startsWith(which('gammaln'),matlabroot)||contains(which('gammaln'),'built-in'));
initial_threads=maxNumCompThreads;
initial_mkl=getenv('MKL_NUM_THREADS'); initial_omp=getenv('OMP_NUM_THREADS');
initial_cbwr=getenv('MKL_CBWR');
assert(initial_threads==1 && strcmp(initial_mkl,'1') && strcmp(initial_omp,'1') && strcmp(initial_cbwr,'COMPATIBLE'));
root=fileparts(mfilename('fullpath'));
out=fullfile(root,'out'); if ~exist(out,'dir'); mkdir(out); end
input=fullfile(root,'input');
raw=fopen(fullfile(input,'inputs.bin'),'r','ieee-le'); assert(raw>0);
bits=fread(raw,4096,'uint64=>uint64'); assert(numel(bits)==4096 && isempty(fread(raw,1,'uint8'))); fclose(raw);
x=typecast(bits,'double');
assert(all(isfinite(x) & x>0) && numel(unique(bits))==4096);
warning('on','all'); warning('off','backtrace');
for rep=1:2
    assert(maxNumCompThreads==1);
    words=fopen(fullfile(out,sprintf('words_%d.bin',rep)),'w','ieee-le');
    status=fopen(fullfile(out,sprintf('status_%d.tsv',rep)),'w');
    assert(words>0 && status>0);
    fprintf(status,'case\tstatus\tclass\trows\tcolumns\terror_id_hex\terror_text_hex\twarning_id_hex\twarning_text_hex\tconsole_hex\n');
    for i=1:numel(x)
        lastwarn('',''); eid=''; emsg=''; console=''; state='returned';
        cls='-'; nr=0; nc=0;
        try
            console=evalc('y=gammaln(x(i));');
        catch ME
            state='error'; eid=ME.identifier; emsg=ME.message;
        end
        [wmsg,wid]=lastwarn;
        if strcmp(state,'returned')
            cls=class(y); nr=size(y,1); nc=size(y,2);
            assert(strcmp(cls,'double') && isreal(y) && isscalar(y));
            fwrite(words,typecast(y,'uint64'),'uint64');
        end
        fprintf(status,'%d\t%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\n',i,state,cls,nr,nc,hextext(eid),hextext(emsg),hextext(wid),hextext(wmsg),hextext(console));
    end
    fclose(words); fclose(status);
end
final_threads=maxNumCompThreads;
final_mkl=getenv('MKL_NUM_THREADS'); final_omp=getenv('OMP_NUM_THREADS'); final_cbwr=getenv('MKL_CBWR');
assert(final_threads==1 && strcmp(final_mkl,'1') && strcmp(final_omp,'1') && strcmp(final_cbwr,'COMPATIBLE'));
prov=struct('classification','V1428_POSITIVE_REAL_GAMMALN_ORIGINAL','V12','SEALED', ...
    'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
    'mkl_cbwr',final_cbwr,'initial_mkl_cbwr',initial_cbwr, ...
    'initial_threads',initial_threads,'final_threads',final_threads, ...
    'initial_mkl_num_threads',initial_mkl,'final_mkl_num_threads',final_mkl, ...
    'initial_omp_num_threads',initial_omp,'final_omp_num_threads',final_omp, ...
    'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'cases',numel(x));
[code,cpu]=system('lscpu'); assert(code==0); prov.lscpu=cpu;
f=fopen(fullfile(out,'provenance.json'),'w'); assert(f>0); fprintf(f,'%s\n',jsonencode(prov)); fclose(f);
end

function h=hextext(s)
if isempty(s); h='-'; else; h=sprintf('%02x',unicode2native(char(s),'UTF-8')); end
end
