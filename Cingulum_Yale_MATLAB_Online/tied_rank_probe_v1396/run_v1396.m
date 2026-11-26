function run_v1396()
% V1396 source-disclosed diagnostic (a probe, not a firstblind): black-box measurements of
% MATLAB's corr with 'type' Spearman on tied ranks (a tied y with itself and with -y, every x
% in {1..k}^n against fixed tied y patterns, as one matrix call and per column) and corr with
% 'type' Kendall with ties for 5 to 10 subjects (cases.csv: case,seed,kind,n,m,mod). For each
% case, twice: the inputs (written out), returned or the error, every named output with
% MATLAB's size and class, the printed text and the last warning. No MEX, no twin, no Rust
% output, no MathWorks source read.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'corr','tiedrank','rng','rand','randi'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(strtrim(lines{1}),'case,seed,kind,n,m,mod'));
fi=fopen(fullfile(outdir,'bb_in.bin'),'w','ieee-le');
fif=fopen(fullfile(outdir,'bb_in_fields.csv'),'w');
o=[fopen(fullfile(outdir,'bb.bin'),'w','ieee-le'),fopen(fullfile(outdir,'bb_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'bb_fields.csv'),'w'),fopen(fullfile(outdir,'bb_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'bb_status.tsv'),'w'),fopen(fullfile(outdir,'bb_status_repeat.tsv'),'w')];
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',','CollapseDelimiters',false);
 assert(numel(f)==6,'bad case line %s',lines{li});
 c=str2double(f{1});seed=str2double(f{2});kind=f{3};n=str2double(f{4});m=str2double(f{5});mods=f{6};
 [X,y]=makedata(seed,kind,n,m,mods);
 ins={X,y};inn={'X','y'};
 for k=1:2
  v=ins{k};fwrite(fi,typecast(double(v(:)),'uint64'),'uint64');
  fprintf(fif,'%d,%s,%d,%d,%s\n',c,inn{k},size(v,1),size(v,2),class(v));
 end
 for rep=1:2
  names={};vals={};ME=[];ok=false; %#ok<NASGU>
  lastwarn('','');
  evalc('try;[names,vals]=measure(kind,X,y);ok=true;catch ME;ok=false;end');
  [lm,lid]=lastwarn;
  if ~ok;names={};vals={};end
  for k=1:numel(vals)
   v=vals{k};
   fwrite(o(rep),typecast(double(v(:)),'uint64'),'uint64');
   fprintf(ff(rep),'%d,%s,%d,%d,%s\n',c,names{k},size(v,1),size(v,2),class(v));
  end
  if ok
   fprintf(fs(rep),'%d\treturned\t-\t-\t%s\t%s\n',c,dash(lid),dash(lm));
  else
   fprintf(fs(rep),'%d\terror\t%s\t%s\t%s\t%s\n',c,dash(ME.identifier),dash(ME.message),dash(lid),dash(lm));
  end
 end
 fprintf('case %d done\n',c);
end
fclose('all');
prov=struct('classification','V1396_SOURCE_DISCLOSED_TIED_RANK_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function [names,vals]=measure(kind,X,y)
m=size(X,2);
switch kind
 case 'eq'
  % X(:,j) is the tied y of column j; pair every column with itself, its negative and an
  % untied companion.
  r_self=zeros(m,1);r_neg=zeros(m,1);r_pair=zeros(2,m);r_matrix_self=zeros(m,1);
  for j=1:m
   x=X(:,j);
   r_self(j)=corr(x,x,'type','Spearman');
   r_neg(j)=corr(-x,x,'type','Spearman');
   u=y+(1:numel(y))'*0;  % untied companion
   rr=corr([x u],x,'type','Spearman');r_pair(:,j)=rr;
  end
  r_matrix_self=corr(X,X(:,1),'type','Spearman');
  names={'r_self','r_neg','r_pair','r_matrix_first'};vals={r_self,r_neg,r_pair,r_matrix_self};
 case 'ex'
  [r,p]=corr(X,y,'type','Spearman');
  r1=zeros(m,1);p1=zeros(m,1);
  for j=1:m;[r1(j),p1(j)]=corr(X(:,j),y,'type','Spearman');end
  names={'r','p','r_one_column','p_one_column'};vals={r,p,r1,p1};
 case 'kd'
  [r,p]=corr(X,y,'type','Kendall');
  names={'r','p'};vals={r,p};
 otherwise;error('bad kind %s',kind);
end
end

function [X,y]=makedata(seed,kind,n,m,mods)
rng(seed,'twister');
switch kind
 case 'eq'
  % column j: values drawn from 1..k with k = 2 + mod(j, n-1), so every tie structure size
  X=zeros(n,m);
  for j=1:m;k=2+mod(j,n-1);X(:,j)=randi(k,n,1);end
  y=rand(n,1);
 case 'ex'
  k=m;y=str2double(strsplit(mods,';'))';
  cnt=k^n;X=zeros(n,cnt);
  for j=1:cnt
   v=j-1;
   for i=1:n;X(i,j)=mod(v,k)+1;v=floor(v/k);end
  end
 case 'kd'
  k=str2double(mods);
  X=randi(k,n,m);y=randi(k+1,n,1);
 otherwise;error('bad kind %s',kind);
end
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
