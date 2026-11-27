function run_v1423()
% V1423 source-disclosed diagnostic (a probe, not a firstblind): MATLAB's own single and mixed
% single/double kernels on Mersenne-twister inputs (cases.csv: case,seed,op,cls,n,m,q). For each
% case, twice: the outputs of corr, partialcorr, [ones Z]\[X y], mldivide with qr(A,0), qr(X,0) with
% Q'*y, R\(Q'*y) and regress, and sum, each with MATLAB's size and class and its raw IEEE words
% (uint32 for single, uint64 for double), or the error (identifier and text), and the last
% warning. Inputs: rng(seed,'twister') then rand, minus 0.5, cast to single where asked; small
% inputs are written out too. No MEX, no twin, no Rust output. Synthetic data only.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'corr','partialcorr','regress','mldivide','qr','sum','mtimes','rng','rand','single','ones'}
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
  rng(seed,'twister');
  X0=rand(n,m)-0.5;y0=rand(n,1)-0.5;Z0=rand(n,q)-0.5;
  if strcmp(op,'corrhi')
   E0=rand(n,m)-0.5;
   for j=1:m;X0(:,j)=(-1)^j*y0+2^-(q+j-1)*E0(:,j);end
  end
  if n*(m+q+1)<=400;names={'in_X','in_y','in_Z'};vals={X0,y0,Z0};end
  lastwarn('','');
  try
   switch op
    case {'corr','corrhi'}
     X=cast1(X0,cls(1));y=cast1(y0,cls(2));
     [r,p]=corr(X,y);names=[names,{'r','p'}];vals=[vals,{r,p}];
    case 'pc'
     X=cast1(X0,cls(1));y=cast1(y0,cls(2));Z=cast1(Z0,cls(3));
     A=[ones(n,1) Z];B=[X y];C=A\B;
     names{end+1}='C';vals{end+1}=C;
     if m<1000;Res=B-A*C;names{end+1}='Res';vals{end+1}=Res;end
     lastwarn('','');
     [r,p]=partialcorr(X,y,Z);names=[names,{'r','p'}];vals=[vals,{r,p}];
    case 'ml'
     A=[ones(n,1) cast1(Z0,cls(1))];B=cast1(X0,cls(2));
     X=A\B;names{end+1}='X';vals{end+1}=X;
     if n>q+1;[~,R,E]=qr(A,0);names=[names,{'R','E'}];vals=[vals,{R,double(E)}];end
    case 'rg'
     X=[cast1(X0,cls(1)) ones(n,1)];y=cast1(y0,cls(2));
     [Q,R,perm]=qr(X,0);Qty=Q'*y;sol=R\Qty;b=regress(y,X);
     names=[names,{'Q','R','perm','Qty','sol','b'}];vals=[vals,{Q,R,double(perm),Qty,sol,b}];
    case 'sum'
     names{end+1}='s';vals{end+1}=sum(single(X0));
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
prov=struct('classification','V1423_SOURCE_DISCLOSED_SINGLE_KERNELS_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function v=cast1(v,c)
switch c
 case 's';v=single(v);
 case 'd'
 otherwise;error('bad class %s',c);
end
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
