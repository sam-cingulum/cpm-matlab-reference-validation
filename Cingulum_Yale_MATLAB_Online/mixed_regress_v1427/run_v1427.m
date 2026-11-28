function run_v1427()
% Fresh input holdout: only original MATLAB is executed here.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
% Capture the initial MATLAB thread limit before making any changes.
initial_threads=maxNumCompThreads;
initial_mkl=getenv('MKL_NUM_THREADS'); initial_omp=getenv('OMP_NUM_THREADS');
initial_cbwr=getenv('MKL_CBWR');
assert(initial_threads==1 && strcmp(initial_mkl,'1') && strcmp(initial_omp,'1') && strcmp(initial_cbwr,'COMPATIBLE'));
for fn={'regress','qr','mldivide'}
    assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
warning('off','backtrace');
warning('on','MATLAB:nearlySingularMatrix');
warning('on','MATLAB:singularMatrix');
warning('on','stats:regress:RankDefDesignMat');
root=fileparts(mfilename('fullpath'));
out=fullfile(root,'out'); if ~exist(out,'dir'); mkdir(out); end
input=fullfile(root,'input');
cases=readtable(fullfile(input,'cases.csv'),'TextType','string');
assert(height(cases)==4794 && isequal(cases{:,'case'},(1:4794)'));
for rep=1:2
    assert(maxNumCompThreads==1);
    raw=fopen(fullfile(input,'inputs.bin'),'r','ieee-le');
    files=[fopen(fullfile(out,sprintf('words_%d.bin',rep)),'w','ieee-le'), ...
        fopen(fullfile(out,sprintf('fields_%d.csv',rep)),'w'), ...
        fopen(fullfile(out,sprintf('status_%d.tsv',rep)),'w')];
    assert(raw>0 && all(files>0));
    fprintf(files(2),'case,field,rows,columns,class,word_bytes\n');
    fprintf(files(3),'case\tstatus\terror_id_hex\terror_text_hex\twarning_id_hex\twarning_text_hex\tconsole_hex\n');
    for i=1:height(cases)
        n=cases.n(i); p=cases.p(i);
        X=fread(raw,[n,p],'double=>double');
        y=fread(raw,[n,1],'single=>single');
        assert(isequal(size(X),[n,p])&&isequal(size(y),[n,1]));
        lastwarn('',''); eid=''; emsg=''; console=''; state='returned';
        try
            console=evalc('b=regress(y,X);');
        catch ME
            state='error'; eid=ME.identifier; emsg=ME.message;
        end
        [wmsg,wid]=lastwarn;
        fprintf(files(3),'%d\t%s\t%s\t%s\t%s\t%s\t%s\n',i,state,hextext(eid),hextext(emsg),hextext(wid),hextext(wmsg),hextext(console));
        if strcmp(state,'returned')
            if isa(b,'single'); fwrite(files(1),typecast(b(:),'uint32'),'uint32'); w=4;
            else; assert(isa(b,'double')); fwrite(files(1),typecast(b(:),'uint64'),'uint64'); w=8; end
            fprintf(files(2),'%d,b,%d,%d,%s,%d\n',i,size(b,1),size(b,2),class(b),w);
        end
    end
    assert(isempty(fread(raw,1,'uint8')));
    fclose(raw); for f=files; fclose(f); end
end
final_threads=maxNumCompThreads;
final_mkl=getenv('MKL_NUM_THREADS'); final_omp=getenv('OMP_NUM_THREADS');
final_cbwr=getenv('MKL_CBWR');
assert(final_threads==1 && strcmp(final_mkl,'1') && strcmp(final_omp,'1') && strcmp(final_cbwr,'COMPATIBLE'));
prov=struct('classification','V1427_FRESH_MIXED_REGRESS_ORIGINAL','V12','SEALED', ...
    'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
    'mkl_cbwr',final_cbwr,'initial_mkl_cbwr',initial_cbwr, ...
    'initial_threads',initial_threads,'final_threads',final_threads, ...
    'initial_mkl_num_threads',initial_mkl,'final_mkl_num_threads',final_mkl, ...
    'initial_omp_num_threads',initial_omp,'final_omp_num_threads',final_omp, ...
    'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
    'cases',height(cases));
[~,cpu]=system('lscpu'); prov.lscpu=cpu;
f=fopen(fullfile(out,'provenance.json'),'w'); assert(f>0); fprintf(f,'%s\n',jsonencode(prov)); fclose(f);
end

function h=hextext(s)
if isempty(s); h='-'; else; h=sprintf('%02x',unicode2native(char(s),'UTF-8')); end
end
