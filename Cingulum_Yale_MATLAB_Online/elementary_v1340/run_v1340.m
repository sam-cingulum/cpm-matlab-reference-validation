function run_v1340()
% V1340 original-only elementary-function probe (source-DISCLOSED diagnostic).
% V1330 showed that 20 of 499 robustfit p-values at one error degree of freedom differ from a
% Cauchy model that uses glibc atan; offline, after that audit, an fdlibm-style atan reproduced
% all 499. This run dumps what genuine MATLAB returns for atan (and acot, tcdf at nu = 1,
% 2*tcdf(-|t|,1)) over every fdlibm reduction interval, and for the other elementary and
% special functions the CPM engine uses (exp, log, log1p, expm1, power, sqrt, sin, cos, tan,
% asin, acos, atan2, sinh, cosh, tanh, gammaln, gamma, erf, erfc, betainc, tcdf nu 1..8),
% with scalar-versus-vector and array-length checks. Synthetic seeded inputs only. No MEX.
% Reads no Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1340_ORIGINAL_ONLY_ELEMENTARY_FUNCTION_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
prov.which_tcdf=which('tcdf');prov.which_acot=which('acot');prov.which_robustfit=which('robustfit');
prov.which_atan=which('atan');prov.which_gammaln=which('gammaln');prov.which_betainc=which('betainc');
% Short excerpts only (the lines that name the arctangent or the nu == 1 case), not the files.
prov.tcdf_lines=grepLines(prov.which_tcdf,'atan|acot|cauchy|Cauchy|== *1\>|==1\>|betainc');
prov.acot_lines=grepLines(prov.which_acot,'atan');
prov.robustfit_lines=grepLines(prov.which_robustfit,'tcdf');
writeJson(fullfile(outdir,'provenance.json'),prov);
warning('off','backtrace');
failed=false;
tStart=tic;
index={};

% ---------------- A. atan and the nu = 1 Student t ----------------
try
rng(134001,'twister');
% Every fdlibm reduction interval and its edges: |x| < 2^-27, < 0.4375, < 0.6875, < 1.1875,
% < 2.4375, < 2^66, beyond; plus a log-uniform sweep 2^-40 .. 2^70 and both signs.
edges=[2^-27 0.4375 0.6875 1.1875 2.4375 2^66];
xe=[];
for e=edges
 u=typecast(e,'int64');
 xe=[xe typecast(u+int64(-64:64),'double')]; %#ok<AGROW>
end
xl=2.^(-40+110*rand(1,120000)).*(1+rand(1,120000));
xu=[rand(1,60000)*3 1./(1e-3+rand(1,20000)*1e3)];
x=[xe xl xu];x=[x -x(1:2:end)];
dumpFn(outdir,'atan',x,[],atan(x));index{end+1}='atan';
dumpFn(outdir,'acot',x,[],acot(x));index{end+1}='acot';
a=2.^(-12+26*rand(1,100000)).*(1+rand(1,100000));
dumpFn(outdir,'tcdf_neg_nu1',a,[],tcdf(-a,1));index{end+1}='tcdf_neg_nu1';
dumpFn(outdir,'p2_tcdf_neg_nu1',a,[],2*tcdf(-abs(a),1));index{end+1}='p2_tcdf_neg_nu1';
dumpFn(outdir,'tcdf_pos_nu1',a,[],tcdf(a,1));index{end+1}='tcdf_pos_nu1';
% Scalar versus vector, and array length: does the result depend on how atan is called?
ns=4000;sc=zeros(1,ns);for i=1:ns;sc(i)=atan(x(i));end
fprintf(logf,'A atan scalar==vector: %d/%d\n',sum(bits(sc)==bits(atan(x(1:ns)))),ns);
ref=atan(x(1:5000));dl=0;
for n=[1:64 100 127 128 129 255 256 257 1000 4096 4097]
 dl=dl+sum(bits(atan(x(1:n)))~=bits(ref(1:n)));
end
fprintf(logf,'A atan prefix-length differences: %d\n',dl);
fprintf(logf,'A done t=%.1f\n',toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. the other elementary functions ----------------
try
rng(134002,'twister');
N=65536;
g=@(lo,hi)2.^(lo+(hi-lo)*rand(1,N)).*(1+rand(1,N));
sg=@(v)v.*(2*(rand(1,N)<0.5)-1);
L={ ...
 'exp',  sg(g(-30,9.4)),[]; ...
 'log',  g(-60,60),[]; ...
 'log1p',[sg(g(-60,-1)) g(-1,40)],[]; ...
 'expm1',sg(g(-60,9)),[]; ...
 'sqrt', g(-60,60),[]; ...
 'sin',  sg(g(-30,20)),[]; ...
 'cos',  sg(g(-30,20)),[]; ...
 'tan',  sg(g(-30,20)),[]; ...
 'asin', sg(rand(1,N)),[]; ...
 'acos', sg(rand(1,N)),[]; ...
 'sinh', sg(g(-30,9)),[]; ...
 'cosh', sg(g(-30,9)),[]; ...
 'tanh', sg(g(-30,5)),[]; ...
 'gammaln',[g(-30,0) g(0,8)],[]; ...
 'gamma',[g(-30,0) 170*rand(1,N)],[]; ...
 'erf',  sg(g(-30,2.6)),[]; ...
 'erfc', [sg(g(-30,1)) 27*rand(1,N)],[]; ...
 };
for i=1:size(L,1)
 nm=L{i,1};v=L{i,2};f=str2func(nm);
 if strcmp(nm,'log1p');v=max(v,-1+eps);end
 dumpFn(outdir,nm,v,[],f(v));index{end+1}=nm; %#ok<AGROW>
 ns=2000;sc=zeros(1,ns);for k=1:ns;sc(k)=f(v(k));end
 fprintf(logf,'B %s scalar==vector: %d/%d\n',nm,sum(bits(sc)==bits(f(v(1:ns)))),ns);
end
xa=sg(g(-20,20));ya=sg(g(-20,20));
dumpFn(outdir,'atan2',ya,xa,atan2(ya,xa));index{end+1}='atan2';
xp=g(-10,10);yp=sg(g(-6,6));
dumpFn(outdir,'power',xp,yp,xp.^yp);index{end+1}='power';
xh=sg(g(-20,20));yh=sg(g(-20,20));
dumpFn(outdir,'hypot',xh,yh,hypot(xh,yh));index{end+1}='hypot';
fprintf(logf,'B done t=%.1f\n',toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- C. betainc and tcdf beyond nu = 1 ----------------
try
rng(134003,'twister');
N=8192;
for nu=1:8
 a=2.^(-12+26*rand(1,N)).*(1+rand(1,N));
 dumpFn(outdir,sprintf('tcdf_neg_nu%d_grid',nu),a,nu+zeros(1,N),tcdf(-a,nu));index{end+1}=sprintf('tcdf_neg_nu%d_grid',nu); %#ok<AGROW>
end
ab=[0.5 0.5;0.5 1;1 0.5;0.5 1.5;1.5 0.5;0.5 2;2 0.5;1 1;2 3;0.5 64;64 0.5];
for q=1:size(ab,1)
 xb=rand(1,N);
 nm=sprintf('betainc_a%g_b%g',ab(q,1),ab(q,2));nm=strrep(nm,'.','p');
 dumpFn(outdir,[nm '_lower'],xb,ab(q,:),betainc(xb,ab(q,1),ab(q,2)));index{end+1}=[nm '_lower']; %#ok<AGROW>
 dumpFn(outdir,[nm '_upper'],xb,ab(q,:),betainc(xb,ab(q,1),ab(q,2),'upper'));index{end+1}=[nm '_upper']; %#ok<AGROW>
end
fprintf(logf,'C done t=%.1f\n',toc(tStart));
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
writeJson(fullfile(outdir,'index.json'),index);
fprintf(logf,'total t=%.1f\n',toc(tStart));
assert(~failed,'a V1340 probe section failed; see out/log.txt');
end

function dumpFn(outdir,name,x,y,z)
% Container CPMEF001: magic, uint64 n, uint64 m (length of the second input, 0 if none),
% then x (n doubles), the second input (m doubles), the result (n doubles).
f=fopen(fullfile(outdir,['fn_' name '.bin']),'w','ieee-le');assert(f>0);
fwrite(f,'CPMEF001','char');fwrite(f,uint64([numel(x) numel(y)]),'uint64');
fwrite(f,double(x(:)),'double');fwrite(f,double(y(:)),'double');fwrite(f,double(z(:)),'double');
fclose(f);
assert(numel(z)==numel(x));
end

function out=grepLines(path,pattern)
out={};
if isempty(path)||~exist(path,'file')||~endsWith(path,'.m');return;end
L=splitlines(fileread(path));
k=find(~cellfun(@isempty,regexp(L,pattern,'once')));
k=k(1:min(numel(k),40));
for i=k(:)';out{end+1}=sprintf('%d: %s',i,strtrim(L{i}));end %#ok<AGROW>
end

function u=bits(a)
u=typecast(double(a(:)),'uint64');
end

function writeJson(path,value)
f=fopen(path,'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(value));
fclose(f);
end
