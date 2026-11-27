function run_v1422()
% V1422 source-disclosed diagnostic (a probe, not a firstblind): MATLAB's own single and mixed
% single/double kernels (cases.csv: case,seed,op,cls,n,m,q). For each case, twice: the outputs
% of corr, partialcorr, [ones Z]\[X y], mldivide, qr(X,0) with Q'*y and regress, sum and
% mtimes, each with MATLAB's size and class and its raw IEEE words (uint32 for single, uint64 for
% double), or the error (identifier and text), and the last warning. Inputs come from gen(), an
% integer hash that is exact in both classes, so nothing has to be written out. No MEX, no twin,
% no Rust output. Synthetic data only.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'corr','partialcorr','regress','mldivide','qr','sum','mtimes','mod','floor','ones'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(strtrim(lines{1}),'case,seed,op,cls,n,m,q'));
o=[fopen(fullfile(outdir,'sk.bin'),'w','ieee-le'),fopen(fullfile(outdir,'sk_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'sk_fields.csv'),'w'),fopen(fullfile(outdir,'sk_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'sk_status.tsv'),'w'),fopen(fullfile(outdir,'sk_status_repeat.tsv'),'w')];
assert(all(o>0)&&all(ff>0)&&all(fs>0));
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',','CollapseDelimiters',false);
 assert(numel(f)==7,'bad case line %s',lines{li});
 c=str2double(f{1});seed=str2double(f{2});op=f{3};cls=f{4};
 n=str2double(f{5});m=str2double(f{6});q=str2double(f{7});
 for rep=1:2
  names={};vals={};ME=[];
  lastwarn('','');
  try
   switch op
    case 'corr'
     X=gen(seed,1,n,m,cls(1));y=gen(seed,2,n,1,cls(2));
     [r,p]=corr(X,y);names={'r','p'};vals={r,p};
    case 'pc'
     X=gen(seed,1,n,m,cls(1));y=gen(seed,2,n,1,cls(2));Z=gen(seed,3,n,q,cls(3));
     A=[ones(n,1) Z];B=[X y];C=A\B;
     names={'C'};vals={C};
     if m<1000;Res=B-A*C;names{end+1}='Res';vals{end+1}=Res;end
     lastwarn('','');
     [r,p]=partialcorr(X,y,Z);names=[names,{'r','p'}];vals=[vals,{r,p}];
    case 'ml'
     Z=gen(seed,3,n,q,cls(1));A=[ones(n,1) Z];B=gen(seed,1,n,m,cls(2));
     X=A\B;names={'X'};vals={X};
     if n>q+1;[~,R,E]=qr(A,0);names=[names,{'R','E'}];vals=[vals,{R,double(E)}];end
    case 'rg'
     Z=gen(seed,1,n,m,cls(1));X=[Z ones(n,1)];y=gen(seed,2,n,1,cls(2));
     [Q,R,perm]=qr(X,0);Qty=Q'*y;sol=R\Qty;b=regress(y,X);
     names={'Q','R','perm','Qty','sol','b'};vals={Q,R,double(perm),Qty,sol,b};
    case 'sum'
     X=gen(seed,1,n,m,'s');names={'s'};vals={sum(X)};
    case 'mt'
     X=gen(seed,1,n,m,cls(1));b=gen(seed,2,m,1,cls(2));names={'Xb'};vals={X*b};
    otherwise;error('bad op %s',op);
   end
   ok=true;
  catch ME
   ok=false;
  end
  [lm,lid]=lastwarn;
  for j=1:numel(vals)
   v=vals{j};
   if isa(v,'single');fwrite(o(rep),typecast(v(:),'uint32'),'uint32');w=4;
   else;fwrite(o(rep),typecast(double(v(:)),'uint64'),'uint64');w=8;end
   fprintf(ff(rep),'%d,%s,%d,%d,%s,%d\n',c,names{j},size(v,1),size(v,2),class(v),w);
  end
  if ok
   fprintf(fs(rep),'%d\treturned\t-\t-\t%s\t%s\n',c,dash(lid),dash(lm));
  else
   fprintf(fs(rep),'%d\terror\t%s\t%s\t%s\t%s\n',c,dash(ME.identifier),dash(ME.message),dash(lid),dash(lm));
  end
 end
 if mod(c,100)==0;fprintf('case %d done\n',c);end
end
fclose('all');
prov=struct('classification','V1422_SOURCE_DISCLOSED_SINGLE_KERNELS_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function v=gen(seed,salt,n,m,cls)
% An integer hash: every step is exact in binary64 (all products stay below 2^53).
s=mod(seed*7+salt*1000003,2^32);
i=(1:n)';j=1:m;
h1=mod(69069*i+1013904223*j+s,2^32);
h2=mod(h1*1664525+1013904223,2^32);
a=floor(h2/256);
switch cls
 case 's';v=single(a/2^24-0.5);
 case 'd';h3=mod(h2*1664525+1013904223,2^32);b=floor(h3/256);v=(a+b/2^24)/2^24-0.5;
 otherwise;error('bad class %s',cls);
end
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
