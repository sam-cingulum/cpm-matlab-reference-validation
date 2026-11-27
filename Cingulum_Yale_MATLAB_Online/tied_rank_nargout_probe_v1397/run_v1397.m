function run_v1397()
% V1397 source-disclosed diagnostic (a probe, not a firstblind): black-box measurements of
% MATLAB's corr with 'type' Spearman on tied ranks with one output and with two, with the
% arguments swapped and with 'tail','right', beside corr (Pearson) of tiedrank(x) and
% tiedrank(y) with one output and with two (cases.csv: case,seed,kind,n,m,mod). For each
% case, twice: the inputs (written out), returned or the error, every named output with
% MATLAB's size and class, the printed text and the last warning. No MEX, no twin, no Rust
% output, no MathWorks source read.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'corr','tiedrank','rng','randn'}
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
prov=struct('classification','V1397_SOURCE_DISCLOSED_TIED_RANK_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function [names,vals]=measure(kind,X,y)
% kind is not used: every case measures the same outputs.
m=size(X,2);
r1=corr(X,y,'type','Spearman');
[r2,p2]=corr(X,y,'type','Spearman');
[r3,p3]=corr(X,y,'type','Spearman','tail','right');
o1=zeros(m,1);o2=zeros(m,1);q2=zeros(m,1);s1=zeros(m,1);s2=zeros(m,1);t2=zeros(m,1);
e1=zeros(m,1);e2=zeros(m,1);f2=zeros(m,1);
ry=tiedrank(y);
for j=1:m
 x=X(:,j);
 o1(j)=corr(x,y,'type','Spearman');
 [o2(j),q2(j)]=corr(x,y,'type','Spearman');
 s1(j)=corr(y,x,'type','Spearman');
 [s2(j),t2(j)]=corr(y,x,'type','Spearman');
 rx=tiedrank(x);
 e1(j)=corr(rx,ry);
 [e2(j),f2(j)]=corr(rx,ry);
end
names={'r_matrix_one_output','r_matrix_two_outputs','p_matrix_two_outputs','r_matrix_tail_right','p_matrix_tail_right', ...
 'r_column_one_output','r_column_two_outputs','p_column_two_outputs','r_swapped_one_output','r_swapped_two_outputs','p_swapped_two_outputs', ...
 'pearson_ranks_one_output','pearson_ranks_two_outputs','pearson_ranks_p'};
vals={r1,r2,p2,r3,p3,o1,o2,q2,s1,s2,t2,e1,e2,f2};
end

function [X,y]=makedata(seed,kind,n,m,mods)
rng(seed,'twister');
switch kind
 case 'nx'
  k=m;y=str2double(strsplit(mods,';'))';
  cnt=k^n;X=zeros(n,cnt);
  for j=1:cnt
   v=j-1;
   for i=1:n;X(i,j)=mod(v,k)+1;v=floor(v/k);end
  end
 case 'nr'
  s=str2double(mods);
  X=round(randn(n,m)*s);y=round(randn(n,1)*s);
 otherwise;error('bad kind %s',kind);
end
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
