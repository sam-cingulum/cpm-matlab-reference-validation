function run_v1390()
% V1390 source-disclosed diagnostic (a probe, not a firstblind): MATLAB's own power operators
% on binary64. Exponent 2 is the one Yale's CPM code raises to (x.^2, x^2, also in MBoxtest);
% the others are probed so no exponent is assumed. Values: 20,000 random finite bit patterns
% (both signs, subnormal to realmax), 10,000 data-like values rand-0.5, the integers 1..2,000 and
% the specials. For each exponent: x.^e on the whole vector and x(i)^e one scalar at a time;
% for 2 also x.*x. No MEX, no Rust output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
rng(1390,'twister');
hi=floor(rand(1,20000)*2^31);lo=floor(rand(1,20000)*2^32);sg=rand(1,20000)<0.5;
w=bitshift(uint64(hi),32)+uint64(lo);
r=typecast(w,'double');r(sg)=-r(sg);r=r(isfinite(r));
d=rand(1,10000)-0.5;
x=[r,d,1:2000,0,-0,Inf,-Inf,NaN,1,-1,2,0.5,eps,realmin,realmax,-realmax,4.9406564584124654e-324];
es=[2,0.5,3,-1,-2,1/3,1.5,4,10,0.25,-0.5,2.5];
f=fopen(fullfile(outdir,'pow.bin'),'w','ieee-le');
fwrite(f,typecast(x(:),'uint64'),'uint64');
for e=es
 v=x.^e;fwrite(f,typecast(v(:),'uint64'),'uint64');
 s=zeros(size(x));for i=1:numel(x);s(i)=x(i)^e;end
 fwrite(f,typecast(s(:),'uint64'),'uint64');
end
m=x.*x;fwrite(f,typecast(m(:),'uint64'),'uint64');
fclose(f);
h=fopen(fullfile(outdir,'pow_layout.txt'),'w');
fprintf(h,'values %d\nexponents %s\norder: x, then per exponent [x.^e, x(i)^e], then x.*x\n',numel(x),strjoin(arrayfun(@(e) num2hex(e),es,'UniformOutput',false),' '));
fclose(h);
prov=struct('classification','V1390_SOURCE_DISCLOSED_POW_PROBE','V12','SEALED','release',version, ...
 'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'values',numel(x));
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end
