function run_v1395()
% V1395 source-disclosed diagnostic (a probe, not a firstblind): black-box measurements of
% MATLAB's own corr (Kendall without ties, Spearman with ties), conv, cumsum, factorial,
% tiedrank, mldivide residuals, partialcorr near the span of its covariates, and corr,
% partialcorr and regress with integer, logical and single inputs (cases.csv:
% case,seed,kind,n,m,q,mod). For each case, twice: the inputs (written out), returned or the
% error (identifier and text), every named output with MATLAB's size and class, the printed
% text and the last warning. No MEX, no twin, no Rust output, no MathWorks source read.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'corr','partialcorr','regress','tiedrank','conv','cumsum','factorial','rng','rand','round','mldivide'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(strtrim(lines{1}),'case,seed,kind,n,m,q,mod'));
fi=fopen(fullfile(outdir,'bb_in.bin'),'w','ieee-le');
fif=fopen(fullfile(outdir,'bb_in_fields.csv'),'w');
o=[fopen(fullfile(outdir,'bb.bin'),'w','ieee-le'),fopen(fullfile(outdir,'bb_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'bb_fields.csv'),'w'),fopen(fullfile(outdir,'bb_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'bb_status.tsv'),'w'),fopen(fullfile(outdir,'bb_status_repeat.tsv'),'w')];
ft=[fopen(fullfile(outdir,'bb_text.tsv'),'w'),fopen(fullfile(outdir,'bb_text_repeat.tsv'),'w')];
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',','CollapseDelimiters',false);
 assert(numel(f)==7,'bad case line %s',lines{li});
 c=str2double(f{1});seed=str2double(f{2});kind=f{3};n=str2double(f{4});m=str2double(f{5});
 q=str2double(f{6});mods=f{7};
 [X,y,Z]=makedata(seed,kind,n,m,q,mods);
 ins={X,y,Z};inn={'X','y','Z'};
 for k=1:3
  v=ins{k};fwrite(fi,typecast(double(v(:)),'uint64'),'uint64');
  fprintf(fif,'%d,%s,%d,%d,%s\n',c,inn{k},size(v,1),size(v,2),class(v));
 end
 for rep=1:2
  names={};vals={};ME=[];ok=false; %#ok<NASGU>
  lastwarn('','');
  txt=evalc('try;[names,vals]=measure(kind,X,y,Z,n,mods);ok=true;catch ME;ok=false;end');
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
prov=struct('classification','V1395_SOURCE_DISCLOSED_CORR_INTERNALS_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function [names,vals]=measure(kind,X,y,Z,n,mods)
names={};vals={};
switch kind
 case 'kt'
  [r,p]=corr(X,y,'type','Kendall');names={'r','p'};vals={r,p};
 case 'kv'
  % The exact null distribution of Kendall's statistic built with MATLAB's own conv.
  fr=1;
  for k=2:n;fr=conv(fr,ones(1,k));end
  names={'f','cumsum_f','cumsum_rev','sum_f','factorial','fp'};
  vals={fr,cumsum(fr),cumsum(fr(end:-1:1)),sum(fr),factorial(n),fr/factorial(n)};
  pr=1;
  for k=2:n;pr=conv(pr,ones(1,k)/k);end
  names{end+1}='prob';vals{end+1}=pr;
  names{end+1}='cumsum_prob';vals{end+1}=cumsum(pr);
 case 'st'
  [r,p]=corr(X,y,'type','Spearman');
  m=size(X,2);R=zeros(size(X));A=zeros(1,m);K3=zeros(3,m);r1=zeros(m,1);p1=zeros(m,1);
  for j=1:m
   [R(:,j),A(j)]=tiedrank(X(:,j));
   [~,kk]=tiedrank(X(:,j),1);K3(:,j)=kk(:);
   [r1(j),p1(j)]=corr(X(:,j),y,'type','Spearman');
  end
  [ry,ay]=tiedrank(y);[~,ky]=tiedrank(y,1);
  [rp,pp]=corr(R,ry);
  names={'r','p','ranks_x','adj_x','kadj_x','ranks_y','adj_y','kadj_y','pearson_r_on_ranks','pearson_p_on_ranks','r_one_column','p_one_column'};
  vals={r,p,R,A,K3,ry,ay,ky(:),rp,pp,r1,p1};
 case 'pz'
  [r,p]=partialcorr(X,y,Z);
  Z1=[ones(size(Z,1),1) Z];
  lastwarn('','');
  B=Z1\[X y];
  E=[X y]-Z1*B;
  names={'r','p','coef','resid','resid_norm','col_norm'};
  vals={r,p,B,E,sqrt(sum(abs(E).^2,1)),sqrt(sum(abs([X y]).^2,1))};
  [r2,p2]=partialcorr(X,y,Z,'type','Spearman');
  names=[names,{'r_spearman','p_spearman'}];vals=[vals,{r2,p2}];
 case 'in'
  [names,vals]=classes(X,y,Z,mods);
 otherwise;error('bad kind %s',kind);
end
end

function [names,vals]=classes(X,y,Z,mods)
switch mods
 case 'yint16';[r,p]=corr(X,int16(y*1000));
 case 'yint32';[r,p]=corr(X,int32(y*1000));
 case 'yuint8';[r,p]=corr(X,uint8(y*100+50));
 case 'ylogical';[r,p]=corr(X,y>0);
 case 'xint16';[r,p]=corr(int16(X*1000),y);
 case 'xlogical';[r,p]=corr(X>0,y);
 case 'ysingle';[r,p]=corr(X,single(y));
 case 'xsingle';[r,p]=corr(single(X),y);
 case 'pyint16';[r,p]=partialcorr(X,int16(y*1000),Z);
 case 'pxint16';[r,p]=partialcorr(int16(X*1000),y,Z);
 case 'pzint16';[r,p]=partialcorr(X,y,int16(Z*1000));
 case 'rgyint16';r=regress(int16(y*1000),[X(:,1:2) ones(size(X,1),1)]);p=[];
 case 'rgxint16';r=regress(y,[int16(X(:,1:2)*1000) ones(size(X,1),1,'int16')]);p=[];
 case 'rgysingle';r=regress(single(y),[X(:,1:2) ones(size(X,1),1)]);p=[];
 otherwise;error('bad mod %s',mods);
end
names={'r','p'};vals={r,p};
end

function [X,y,Z]=makedata(seed,kind,n,m,q,mods)
rng(seed,'twister');
X=[];y=[];Z=[];
switch kind
 case 'kt'
  X=rand(n,m)-0.5;y=rand(n,1)-0.5;
  for j=1:m;w=2*(j-1)/m;t=w*y;X(:,j)=X(:,j)+t;end
 case 'kv'
 case 'st'
  X=rand(n,m)-0.5;y=rand(n,1)-0.5;
  for j=1:m;w=(j-1)/m;t=w*y;X(:,j)=X(:,j)+t;end
  switch mods
   case 'y';y=round(y*4)/4;
   case 'x';X=round(X*4)/4;
   case 'xy';y=round(y*4)/4;X=round(X*4)/4;
   case 'heavy';y=round(y*1.5);X=round(X*1.5);
   case 'one';y(2)=y(1);
   otherwise;error('bad mod %s',mods);
  end
 case 'pz'
  Z=rand(n,q)-0.5;w=rand(n,1)-0.5;y=rand(n,1)-0.5;u=rand(n,m)-0.5;
  base=0.75+Z*(0.5+(1:q)'/4);
  switch mods
   case 'x'
    % columns at distance 2^e times w from the span, e = -62, -61.75, ..., -36
    X=zeros(n,m);
    for j=1:m;d=2^(-62+(j-1)/4);t=d*w;X(:,j)=base+t;end
   case 'xs'
    % half the columns exactly in the span (scaled), half far from it
    X=u;
    for j=1:2:m;s=2^((j-20)/4);X(:,j)=s*base;end
   case 'y'
    X=u;
    j=mod(n+q,9);d=2^(-58+3*j);t=d*w;y=base+t;
   otherwise;error('bad mod %s',mods);
  end
 case 'in'
  X=rand(n,m)-0.5;y=rand(n,1)-0.5;Z=rand(n,q)-0.5;
  for j=1:m;w=(j-1)/m;t=w*y;X(:,j)=X(:,j)+t;end
 otherwise;error('bad kind %s',kind);
end
end

function s=hexbytes(t)
s=sprintf('%02x',uint8(char(t)));if isempty(s);s='00';end
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
