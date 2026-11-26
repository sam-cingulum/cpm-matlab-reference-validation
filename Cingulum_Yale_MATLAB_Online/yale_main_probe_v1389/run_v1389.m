function run_v1389()
% V1389 source-disclosed diagnostic (a probe, not a firstblind): Yale's own functional CPM,
% cpm_main with cpm_check_errors, cpm_cv, cpm_train and cpm_test (YaleMRRC/CPM b903f83,
% matlab/func, unchanged), called the way a caller calls it (cases.csv:
% case,seed,form,nr,nc,n,ties,y,mod,args). Each cohort comes from MATLAB's own generator (the
% V1386 one); rng(seed,'twister') is set just before cpm_main, so cpm_cv draws MATLAB's own
% randperm. For each case, twice: returned or the error (identifier and text), y_predict and
% performance with MATLAB's size and class, one draw after cpm_main, the printed text
% (warnings included, also when cpm_main errors) and the last warning. Once per returned case,
% a diagnostic rerun of Yale's own cpm_train on each fold (masks, coefficients). No MEX, no
% twin, no Rust output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
fdir=fullfile(root,'upstream','matlab','func');addpath(fdir);
for fn={'cpm_main','cpm_check_errors','cpm_cv','cpm_train','cpm_test'}
 assert(strcmp(which(fn{1}),fullfile(fdir,[fn{1} '.m'])),'%s is not the pinned Yale file',fn{1});
end
for fn={'corr','robustfit','nanmean','randperm','setdiff','inputParser','issymmetric','squeeze','rng','rand','triu'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(strtrim(lines{1}),'case,seed,form,nr,nc,n,ties,y,mod,args'));
o=[fopen(fullfile(outdir,'main.bin'),'w','ieee-le'),fopen(fullfile(outdir,'main_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'main_fields.csv'),'w'),fopen(fullfile(outdir,'main_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'main_status.tsv'),'w'),fopen(fullfile(outdir,'main_status_repeat.tsv'),'w')];
ft=[fopen(fullfile(outdir,'main_text.tsv'),'w'),fopen(fullfile(outdir,'main_text_repeat.tsv'),'w')];
fk=fopen(fullfile(outdir,'main_stack.tsv'),'w');
fd=fopen(fullfile(outdir,'main_diag.tsv'),'w');
fp=fopen(fullfile(outdir,'main_perm.bin'),'w','ieee-le');
ftime=fopen(fullfile(outdir,'main_time.tsv'),'w');
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',','CollapseDelimiters',false);
 if numel(f)==9;f{10}='';end
 assert(numel(f)==10,'bad case line %s',lines{li});
 c=str2double(f{1});seed=str2double(f{2});form=f{3};nr=str2double(f{4});nc=str2double(f{5});
 n=str2double(f{6});ties=str2double(f{7});ymode=f{8};mods=f{9};spec=f{10};
 for rep=1:2
  t0=tic;
  [x,y]=makedata(seed,form,nr,nc,n,ties,ymode,mods);
  a=callargs(spec);
  yp=[];pf=[];ME=[];ok=false; %#ok<NASGU>
  lastwarn('','');
  rng(seed,'twister');
  if strcmp(ymode,'none')
   txt=evalc('try;[yp,pf]=cpm_main(x);ok=true;catch ME;ok=false;end');
  else
   txt=evalc('try;[yp,pf]=cpm_main(x,y,a{:});ok=true;catch ME;ok=false;end');
  end
  nxt=rand;
  [lm,lid]=lastwarn;
  if ok
   names={'y_predict','performance','next'};vals={yp,pf,nxt};
  else
   names={'next'};vals={nxt};
  end
  for q=1:numel(vals)
   v=vals{q};[r,k]=size(v);
   fwrite(o(rep),typecast(double(v(:)),'uint64'),'uint64');
   fprintf(ff(rep),'%d,%s,%d,%d,%s\n',c,names{q},r,k,class(v));
  end
  if ok
   fprintf(fs(rep),'%d\treturned\t-\t-\t%s\t%s\n',c,dash(lid),dash(lm));
  else
   fprintf(fs(rep),'%d\terror\t%s\t%s\t%s\t%s\n',c,dash(ME.identifier),dash(ME.message),dash(lid),dash(lm));
   if rep==1
    for s=1:numel(ME.stack);fprintf(fk,'%d\t%d\t%s\t%d\n',c,s,dash(ME.stack(s).name),ME.stack(s).line);end
   end
  end
  fprintf(ft(rep),'%d\t%s\n',c,hexbytes(txt));
  if rep==1
   fprintf(ftime,'%d\t%.3f\n',c,toc(t0));
   if ok;diagnose(fd,fp,c,seed,x,y,a);end
  end
  clear x y yp pf
 end
 fprintf('case %d done\n',c);
end
fclose('all');
prov=struct('classification','V1389_SOURCE_DISCLOSED_YALE_CPM_MAIN_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'yale_commit',getenv('YALE_COMMIT'),'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function diagnose(fd,fp,c,seed,x,y,a)
% The same parse as cpm_main, then Yale's own cpm_check_errors and cpm_train on each fold,
% with the fold split of cpm_cv. Only for plain positive whole kfolds of class double.
p=inputParser;
addRequired(p,'x',@isnumeric);addRequired(p,'y',@isnumeric);
addParameter(p,'pthresh',0.01,@isnumeric);addParameter(p,'kfolds',2,@isnumeric);
parse(p,x,y,a{:});
pth=p.Results.pthresh;k=p.Results.kfolds;
if ~(isa(k,'double')&&isscalar(k)&&k>=1&&k==floor(k)&&isfinite(k));return;end
dx=[];dy=[];
evalc('[dx,dy]=cpm_check_errors(x,y,k);');
nsubs=size(dx,2);
if k>nsubs;return;end
rng(seed,'twister');perm=randperm(nsubs);
fwrite(fp,typecast(double(perm(:)),'uint64'),'uint64');
ks=floor(nsubs/k);
for j=1:k
 if k==nsubs;te=perm(j);else;te=perm(1+(j-1)*ks:j*ks);end
 tr=setdiff(perm,te);
 lastwarn('','');
 try
  r=[];pv=[];mask=[];mdl=[];
  evalc('[r,pv,mask,mdl]=cpm_train(dx(:,tr),dy(tr),pth);');
  [~,lid]=lastwarn;
  fprintf(fd,'%d\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\n',c,j,numel(te),nnz(mask>0),nnz(mask<0),nnz(isnan(r)), ...
   hexwords(mdl),hexwords(sum(r(~isnan(r)))),hexwords(sum(pv(~isnan(pv)))),dash(lid));
 catch e
  fprintf(fd,'%d\t%d\t%d\terror\t%s\t%s\n',c,j,numel(te),dash(e.identifier),dash(e.message));
 end
end
end

function [x,y]=makedata(seed,form,nr,nc,n,ties,ymode,mods)
nb=1;if startsWith(ymode,'mat2');nb=2;end
switch form
 case 's';[A,B]=cohort(seed,nr,nc,n,1,0,nb,ties);x=A;
 case 'a';[A,B]=cohort(seed,nr,nc,n,1,2,nb,ties);x=A;
 case 'n';[A,B]=cohort(seed,nr,nc,n,1,1,nb,ties);x=A;
 case 'f';[~,B,E]=cohort(seed,nr,nc,n,1,1,nb,ties);x=E;
 case '4';[A,B]=cohort(seed,nr,nc,n,2,0,nb,ties);x=A;
 otherwise;error('bad form %s',form);
end
clear A E
y=B(:,1);
if nb==2;y=B;end
if ~strcmp(mods,'-')
 for m=strsplit(mods,';')
  switch m{1}
   case 'nan2'
    if ismatrix(x);x(1,2)=NaN;else;x(1,2,2)=NaN;x(2,1,2)=NaN;end
   case 'nan1';x(1,2,1)=NaN;
   case 'nanedge';x(5,4,3:7)=NaN;x(4,5,3:7)=NaN;
   case 'nansel';x(1,2,[3 11 19])=NaN;x(2,1,[3 11 19])=NaN;
   case 'nanall';x(:,:,3)=NaN;
   case 'inf2';x(1,3,2)=Inf;x(3,1,2)=Inf;
   case 'ninf2';x(1,3,2)=-Inf;x(3,1,2)=-Inf;
   case 'negzero';x(1,2,3)=-0;x(2,1,3)=-0;
   case 'zero';x(3,:,4)=0;x(:,3,4)=0;
   case 'zero3';for s=[2 5 9];x(3,:,s)=0;x(:,3,s)=0;end
   case 'const';x(2,1,:)=0.25;x(1,2,:)=0.25;
   case 'ynan';y(4)=NaN;
   case 'yconst';y(:)=0.5;
   case 'logical';x=x>0;
   case 'single';x=single(x);
   case 'int16';x=int16(x*1000);
   case 'ysingle';y=single(y);
   case 'yint16';y=int16(y*1000);
   case 'ylogical';y=y>0;
   case 'empty';x=[];
   otherwise;error('bad mod %s',m{1});
  end
 end
end
switch ymode
 case {'col','none','mat2'}
 case 'row';y=y.';
 case 'mat2t';y=y.';
 case 'short';y=y(1:end-1);
 otherwise;error('bad y %s',ymode);
end
end

function a=callargs(spec)
a={};
if isempty(spec);return;end
for t=strsplit(spec,'|')
 tv=t{1};i=find(tv==':',1);ty=tv(1:i-1);v=tv(i+1:end);
 switch ty
  case 'c';a{end+1}=v; %#ok<*AGROW>
  case 'q';a{end+1}=string(v);
  case 'd';a{end+1}=str2double(v);
  case 'i';a{end+1}=int32(str2double(v));
  case 'l';a{end+1}=strcmp(v,'true');
  case 'e';a{end+1}=[];
  case 'v';a{end+1}=str2double(strsplit(v,';'));
  case 'st'
   s=struct();
   if ~isempty(v)
    for kv=strsplit(v,';');q=strsplit(kv{1},'=');s.(q{1})=str2double(q{2});end
   end
   a{end+1}=s;
  otherwise;error('bad argument type %s',ty);
 end
end
end

function [A,B,E]=cohort(seed,nr,nc,n,nt,kind,nb,ties)
% One statement per operation, so no two operations can be fused (V1386's generator).
rng(seed,'twister');
if kind==1;ne=nr*nc;else;ne=nr*(nr-1)/2;end
% Fewer than three features (V1389 only, one task): draw three rows for the signal, keep ne.
E=rand(max(ne,3)*nt,n)-0.5;U=rand(n,nb)-0.5;
s=E(1,:).';t=0.5*E(2,:).';s=s-t;t=0.25*E(3,:).';s=s+t;
if ne<3;assert(nt==1);E=E(1:ne,:);end
B=zeros(n,nb);
for m=1:nb;t=(0.2*m)*U(:,m);B(:,m)=s+t;end
if ties;B=round(B*4)/4;end
if nargout>2;A=[];return;end
A=zeros(nr,nc,n,nt);L=tril(true(nr),-1);
for tk=1:nt
 for i=1:n
  v=E((tk-1)*ne+(1:ne),i);
  if kind==1
   A(:,:,i,tk)=reshape(v,nr,nc);
  else
   M=zeros(nr);M(L)=v;
   if kind==0||i==1;M=M+M.';else;M=M+2*M.';end
   A(:,:,i,tk)=M;
  end
 end
end
end

function s=hexwords(v)
s=strjoin(cellstr(num2hex(double(v(:)))),' ');if isempty(s);s='-';end
end

function s=hexbytes(t)
s=sprintf('%02x',uint8(char(t)));if isempty(s);s='00';end
end

function s=dash(s)
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
