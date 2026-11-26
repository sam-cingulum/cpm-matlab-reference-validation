function run_v1393()
% V1393 source-disclosed diagnostic (a probe, not a firstblind): MATLAB's own corr with
% 'type' Spearman, Kendall and Pearson, partialcorr with 'type' Spearman and Pearson, and
% regress with one output, the way Yale's OHBM K-fold CPM calls them (cases.csv:
% case,seed,kind,n,m,q,ties,mod). For each case, twice: the inputs (written out, so nothing has
% to regenerate them), returned or the error (identifier and text), the outputs with MATLAB's
% size and class, the printed text and the last warning. No MEX, no twin, no Rust output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'corr','partialcorr','regress','tiedrank','rng','rand','round'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(strtrim(lines{1}),'case,seed,kind,n,m,q,ties,mod'));
fi=fopen(fullfile(outdir,'bb_in.bin'),'w','ieee-le');
fif=fopen(fullfile(outdir,'bb_in_fields.csv'),'w');
o=[fopen(fullfile(outdir,'bb.bin'),'w','ieee-le'),fopen(fullfile(outdir,'bb_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'bb_fields.csv'),'w'),fopen(fullfile(outdir,'bb_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'bb_status.tsv'),'w'),fopen(fullfile(outdir,'bb_status_repeat.tsv'),'w')];
ft=[fopen(fullfile(outdir,'bb_text.tsv'),'w'),fopen(fullfile(outdir,'bb_text_repeat.tsv'),'w')];
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',','CollapseDelimiters',false);
 assert(numel(f)==8,'bad case line %s',lines{li});
 c=str2double(f{1});seed=str2double(f{2});kind=f{3};n=str2double(f{4});m=str2double(f{5});
 q=str2double(f{6});ties=str2double(f{7});mods=f{8};
 [X,y,Z]=makedata(seed,kind,n,m,q,ties,mods);
 ins={X,y,Z};inn={'X','y','Z'};
 for k=1:3
  v=ins{k};fwrite(fi,typecast(double(v(:)),'uint64'),'uint64');
  fprintf(fif,'%d,%s,%d,%d,%s\n',c,inn{k},size(v,1),size(v,2),class(v));
 end
 for rep=1:2
  r=[];p=[];b=[];ME=[];ok=false; %#ok<NASGU>
  lastwarn('','');
  switch kind
   case {'cs','ck','cp'}
    ty=struct('cs','Spearman','ck','Kendall','cp','Pearson');ty=ty.(kind);
    txt=evalc('try;[r,p]=corr(X,y,''type'',ty);ok=true;catch ME;ok=false;end');
    names={'r','p'};vals={r,p};
   case {'ps','pp'}
    ty=struct('ps','Spearman','pp','Pearson');ty=ty.(kind);
    txt=evalc('try;[r,p]=partialcorr(X,y,Z,''type'',ty);ok=true;catch ME;ok=false;end');
    names={'r','p'};vals={r,p};
   case 'rg'
    txt=evalc('try;b=regress(y,X);ok=true;catch ME;ok=false;end');
    names={'b'};vals={b};
   otherwise;error('bad kind %s',kind);
  end
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
  fprintf(ft(rep),'%d\t%s\n',c,hexbytes(txt));
 end
 fprintf('case %d done\n',c);
end
fclose('all');
prov=struct('classification','V1393_SOURCE_DISCLOSED_CORR_PARTIALCORR_REGRESS_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function [X,y,Z]=makedata(seed,kind,n,m,q,ties,mods)
rng(seed,'twister');
if strcmp(kind,'rg')
 a=rand(n,1)-0.5;b=rand(n,1)-0.5;e=rand(n,1)-0.5;
 t=0.7*a;y=t;t=0.4*b;y=y-t;t=0.3*e;y=y+t;
 switch mods
  case '-'
  case 'zero1';a(:)=0;
  case 'zero2';b(:)=0;
  case 'zero12';a(:)=0;b(:)=0;
  case 'dup';b=a;
  case 'neg';a=-a;b=-b;
  case 'scale';a=a*1e6;
  case 'tiny';a=a*1e-14;
  case 'nanrow';a(min(2,n))=NaN;
  case 'nanall';a(:)=NaN;
  case 'ynan';y(min(3,n))=NaN;
  case 'yall';y(:)=NaN;
  case 'inf';a(min(2,n))=Inf;
  case 'ninf';b(min(2,n))=-Inf;
  case 'negzero';a(:)=-0;
  case 'const1';a(:)=0.25;
  case 'int';a=round(a*10);b=round(b*10);
  case 'near';t=1e-13*e;b=a+t;
  otherwise;error('bad mod %s',mods);
 end
 X=[a,b,ones(n,1)];Z=[];
 return
end
X=rand(n,m)-0.5;y=rand(n,1)-0.5;Z=rand(n,q)-0.5;
if q>0
 t=0.5*Z(:,1);y=y+t;
 for j=1:2:m;t=0.3*Z(:,1);X(:,j)=X(:,j)+t;end
end
for j=1:m
 w=(j-1)/m;t=w*y;X(:,j)=X(:,j)+t;
end
switch ties
 case 0
 case 1;y=round(y*4)/4;
 case 2;X=round(X*4)/4;
 case 3;y=round(y*4)/4;X=round(X*4)/4;
 case 4;y=round(y*1.5);X=round(X*1.5);
end
switch mods
 case '-'
 case 'xnan';X(3,2)=NaN;
 case 'ynan';y(2)=NaN;
 case 'xinf';X(4,3)=Inf;
 case 'xconst';X(:,5)=0.25;
 case 'yconst';y(:)=0.5;
 case 'znan';Z(1)=NaN;
 case 'zconst';Z(:,1)=0.5;
 case 'zdup';Z(:,2)=Z(:,1);
 case 'zbin';Z=double(Z>0);
 otherwise;error('bad mod %s',mods);
end
end

function s=hexbytes(t)
s=sprintf('%02x',uint8(char(t)));if isempty(s);s='00';end
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
