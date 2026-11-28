function run_v1426()
% Source-disclosed diagnostic for the mixed single/double triangular solve
% warning in V1422. Every operation has its own lastwarn reset. No forecast.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1); assert(maxNumCompThreads==1);
for fn={'mldivide','rcond','qr','regress','mtimes'}
    assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
warning('off','backtrace');
warning('on','MATLAB:nearlySingularMatrix');
warning('on','MATLAB:singularMatrix');
warning('on','stats:regress:RankDefDesignMat');
root=fileparts(mfilename('fullpath'));
out=fullfile(root,'out'); if ~exist(out,'dir'); mkdir(out); end
ratios=[2^-28 2^-25 2^-24 double(eps('single'))*(1-2^-24) ...
    double(eps('single')) double(eps('single'))*(1+2^-23) 2^-20];
counts=zeros(1,2);
for rep=1:2
    files=[fopen(fullfile(out,sprintf('words_%d.bin',rep)),'w','ieee-le'), ...
        fopen(fullfile(out,sprintf('fields_%d.csv',rep)),'w'), ...
        fopen(fullfile(out,sprintf('status_%d.tsv',rep)),'w'), ...
        fopen(fullfile(out,sprintf('cases_%d.csv',rep)),'w')];
    assert(all(files>0));
    fprintf(files(2),'case,stage,field,rows,columns,class,word_bytes\n');
    fprintf(files(3),'case\tstage\tstatus\terror_id_hex\terror_text_hex\twarning_id_hex\twarning_text_hex\tconsole_hex\n');
    fprintf(files(4),'case,kind,n,p,weak,orientation,pattern,ratio,scale,seed\n');
    c=0;
    % Independent upper/lower triangles, all weak-diagonal positions,
    % signed unequal diagonal, four off-diagonal patterns, scale and eps sweep.
    for n=2:4
        for weak=1:n
            for orientation=1:2
                for pattern=0:3
                    for ratio=ratios
                        for scale=[-24 0 24]
                            c=c+1;
                            d=(-1).^(1:n).*(1+(1:n)/4);
                            d(weak)=(-1)^weak*ratio*max(abs(d));
                            T=diag(d);
                            for j=2:n
                                for i=1:j-1
                                    if pattern==1; T(i,j)=(-1)^(i+j)/4;
                                    elseif pattern==2; T(i,j)=(-1)^i*(i+j)/2;
                                    elseif pattern==3; T(i,j)=(-1)^j*2^(j-i+1);
                                    end
                                end
                            end
                            if orientation==2; T=T.'; end
                            T=T*2^scale;
                            B=((1:n)'-1.5)*2^scale;
                            fprintf(files(4),'%d,triangle,%d,%d,%d,%d,%d,%.17g,%d,0\n',c,n,n,weak,orientation,pattern,ratio,scale);
                            record(files,c,'input',{'T','B'},{T,B});
                            observe(files,c,'rcond_d',{'value'},@(){rcond(T)});
                            observe(files,c,'rcond_s',{'value'},@(){rcond(single(T))});
                            observe(files,c,'solve_dd',{'x'},@(){T\B});
                            observe(files,c,'solve_ds',{'x'},@(){T\single(B)});
                            observe(files,c,'solve_sd',{'x'},@(){single(T)\B});
                            observe(files,c,'solve_ss',{'x'},@(){single(T)\single(B)});
                        end
                    end
                end
            end
        end
    end
    % Exact regeneration of the five refused V1422 mixed regress inputs.
    ns=[3 4 5 8 9];
    for k=1:5
        c=c+1; n=ns(k); seed=142203038+k;
        X=[oldgen(seed,1,n,2,false) ones(n,1)];
        y=oldgen(seed,2,n,1,true);
        fprintf(files(4),'%d,v1422_replay,%d,3,0,0,0,0,0,%d\n',c,n,seed);
        regress_case(files,c,X,y);
    end
    % Independent nearly dependent, well-conditioned and scale-varied designs.
    for n=[4 5 8 9 17 65 257 1000]
        for p=2:4
            for pattern=1:3
                for ratio=[ratios 2^-12 1]
                    c=c+1; seed=142600000+c; rng(seed,'twister');
                    Z=randn(n,p-1);
                    scale=12*(pattern-2);
                    if p==2; Z(:,1)=1+ratio*Z(:,1);
                    else; Z(:,end)=(-1)^pattern*Z(:,1)+ratio*Z(:,end); end
                    if pattern==3; Z=Z(:,end:-1:1); end
                    X=[Z*2^scale ones(n,1)];
                    y=single(randn(n,1));
                    fprintf(files(4),'%d,regress,%d,%d,0,0,%d,%.17g,%d,%d\n',c,n,p,pattern,ratio,scale,seed);
                    regress_case(files,c,X,y);
                end
            end
        end
    end
    for f=files; fclose(f); end
    counts(rep)=c;
end
assert(counts(1)==counts(2));
prov=struct('classification','V1426_SOURCE_DISCLOSED_MIXED_TRIANGULAR_WARNING_PROBE','V12','SEALED', ...
    'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
    'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
    'cases',counts(1));
[~,cpu]=system('lscpu'); prov.lscpu=cpu;
f=fopen(fullfile(out,'provenance.json'),'w'); assert(f>0); fprintf(f,'%s\n',jsonencode(prov)); fclose(f);
fprintf('V1426 cases per repetition: %d\n',counts(1));
end

function regress_case(files,c,X,y)
record(files,c,'input',{'X','y'},{X,y});
v=observe(files,c,'qr',{'Q','R','perm'},@()qr_cells(X));
if ~isempty(v)
    Q=v{1}; R=v{2};
    q=observe(files,c,'qty',{'value'},@(){Q'*y});
    observe(files,c,'rcond_d',{'value'},@(){rcond(R)});
    observe(files,c,'rcond_s',{'value'},@(){rcond(single(R))});
    if ~isempty(q); observe(files,c,'triangular',{'x'},@(){R\q{1}}); end
end
observe(files,c,'regress',{'b'},@(){regress(y,X)});
end

function v=qr_cells(X)
[Q,R,E]=qr(X,0); v={Q,R,double(E)};
end

function v=observe(files,c,stage,names,fun)
lastwarn('',''); v={}; eid=''; emsg=''; console=''; state='returned';
try
    console=evalc('v=fun();');
catch ME
    state='error'; eid=ME.identifier; emsg=ME.message;
end
[wmsg,wid]=lastwarn;
fprintf(files(3),'%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',c,stage,state,hextext(eid),hextext(emsg),hextext(wid),hextext(wmsg),hextext(console));
if strcmp(state,'returned'); record(files,c,stage,names,v); end
end

function record(files,c,stage,names,values)
assert(numel(names)==numel(values));
for j=1:numel(values)
    v=values{j};
    if isa(v,'single'); fwrite(files(1),typecast(v(:),'uint32'),'uint32'); w=4;
    else; assert(isa(v,'double')); fwrite(files(1),typecast(v(:),'uint64'),'uint64'); w=8; end
    fprintf(files(2),'%d,%s,%s,%d,%d,%s,%d\n',c,stage,names{j},size(v,1),size(v,2),class(v),w);
end
end

function h=hextext(s)
if isempty(s); h='-'; else; h=sprintf('%02x',unicode2native(char(s),'UTF-8')); end
end

function v=oldgen(seed,salt,n,m,is_single)
s=mod(seed*7+salt*1000003,2^32); i=(1:n)'; j=1:m;
h1=mod(69069*i+1013904223*j+s,2^32);
h2=mod(h1*1664525+1013904223,2^32); a=floor(h2/256);
if is_single; v=single(a/2^24-0.5);
else; h3=mod(h2*1664525+1013904223,2^32); b=floor(h3/256); v=(a+b/2^24)/2^24-0.5; end
end
