function run_v1394()
% V1394 preregistered original-only firstblind: Yale's OHBM K-fold CPM, kfold_cpm_withmatrix and
% kfold_cpm_partial_withmatrix (YaleMRRC/CPM_OHBM 708999b, unchanged), called the way a caller
% calls them (cases.csv: case,seed,fn,N,n,nsig,ties,score,covar,mod,args). Each cohort comes from
% MATLAB's own generator (cohort below, the V1392 probe's, unchanged); rng(seed,'twister') is set
% just before the call, so randperm is MATLAB's own. For each case, twice: returned or the error
% (identifier and text), all_r, all_p, pred_all, every pos_mat and neg_mat cell with MATLAB's
% size and class, one draw after the call, the printed text (warnings included, also when the
% call errors) and the last warning. The Rust forecast was frozen before this ran; this script
% reads no forecast, no MEX, no twin and no Rust output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
fdir=fullfile(root,'upstream');addpath(fdir);
for fn={'kfold_cpm_withmatrix','kfold_cpm_partial_withmatrix'}
 assert(strcmp(which(fn{1}),fullfile(fdir,[fn{1} '.m'])),'%s is not the pinned Yale file',fn{1});
end
for fn={'corr','partialcorr','regress','randperm','triu','find','reshape','round','sum','rng','rand','ones','zeros','cell','transpose'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(strtrim(lines{1}),'case,seed,fn,N,n,nsig,ties,score,covar,mod,args'));
o=[fopen(fullfile(outdir,'kfold.bin'),'w','ieee-le'),fopen(fullfile(outdir,'kfold_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'kfold_fields.csv'),'w'),fopen(fullfile(outdir,'kfold_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'kfold_status.tsv'),'w'),fopen(fullfile(outdir,'kfold_status_repeat.tsv'),'w')];
ft=[fopen(fullfile(outdir,'kfold_text.tsv'),'w'),fopen(fullfile(outdir,'kfold_text_repeat.tsv'),'w')];
fk=fopen(fullfile(outdir,'kfold_stack.tsv'),'w');
ftime=fopen(fullfile(outdir,'kfold_time.tsv'),'w');
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',','CollapseDelimiters',false);
 if numel(f)==10;f{11}='';end
 assert(numel(f)==11,'bad case line %s',lines{li});
 c=str2double(f{1});seed=str2double(f{2});fnk=f{3};N=str2double(f{4});n=str2double(f{5});
 nsig=str2double(f{6});ties=str2double(f{7});smode=f{8};cmode=f{9};mods=f{10};spec=f{11};
 for rep=1:2
  t0=tic;
  [x,y,cv]=makedata(seed,N,n,nsig,ties,smode,cmode,mods);
  a=callargs(spec);
  ar=[];ap=[];pm=[];nm=[];pa=[];ME=[];ok=false; %#ok<NASGU>
  lastwarn('','');
  rng(seed,'twister');
  switch fnk
   case 'k'
    if strcmp(smode,'none')
     txt=evalc('try;[ar,ap,pm,nm,pa]=kfold_cpm_withmatrix(x);ok=true;catch ME;ok=false;end');
    else
     txt=evalc('try;[ar,ap,pm,nm,pa]=kfold_cpm_withmatrix(x,y,a{:});ok=true;catch ME;ok=false;end');
    end
   case 'p'
    if strcmp(cmode,'none')
     txt=evalc('try;[ar,ap,pm,nm,pa]=kfold_cpm_partial_withmatrix(x,y,a{:});ok=true;catch ME;ok=false;end');
    else
     txt=evalc('try;[ar,ap,pm,nm,pa]=kfold_cpm_partial_withmatrix(x,y,cv,a{:});ok=true;catch ME;ok=false;end');
    end
   otherwise;error('bad fn %s',fnk);
  end
  nxt=rand;
  [lm,lid]=lastwarn;
  if ok
   names={'all_r','all_p','pred_all'};vals={ar,ap,pa};
   names{end+1}='pos_mat';vals{end+1}=size(pm);
   for q=1:numel(pm);names{end+1}=sprintf('pos_mat{%d}',q);vals{end+1}=pm{q};end
   names{end+1}='neg_mat';vals{end+1}=size(nm);
   for q=1:numel(nm);names{end+1}=sprintf('neg_mat{%d}',q);vals{end+1}=nm{q};end
   names{end+1}='next';vals{end+1}=nxt;
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
  end
  clear x y cv ar ap pm nm pa
 end
 fprintf('case %d done\n',c);
end
fclose('all');
prov=struct('classification','V1394_ORIGINAL_ONLY_OHBM_KFOLD_FIRSTBLIND','V12','SEALED','forecast_read',false, ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'ohbm_commit',getenv('OHBM_COMMIT'),'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function [x,y,cv]=makedata(seed,N,n,nsig,ties,smode,cmode,mods)
nb=1;if strcmp(smode,'mat2');nb=2;end
nc=0;
switch cmode
 case {'none','e'}
 case {'c1','c1s','r1','cnan','cshort','cbin','cconst','cinf'};nc=1;
 case {'c2','r2','cdup'};nc=2;
 case 'c3';nc=3;
 otherwise;error('bad covar %s',cmode);
end
[x,B,C,s]=cohort(seed,N,n,nsig,ties,nb,nc);
y=B(:,1);
if nb==2;y=B;end
cv=C;
switch cmode
 case {'none','e'};cv=[];
 case {'c1','c2','c3'}
 case 'c1s';t=0.5*s;cv=cv+t;
 case 'r1';cv=cv.';
 case 'r2';cv=cv.';
 case 'cnan';cv(4)=NaN;
 case 'cinf';cv(4)=Inf;
 case 'cshort';cv=cv(1:end-1);
 case 'cbin';cv=double(cv>0);
 case 'cconst';cv(:)=0.5;
 case 'cdup';cv(:,2)=cv(:,1);
end
if ~strcmp(mods,'-')
 for mm=strsplit(mods,';')
  switch mm{1}
   case 'nan2';x(1,2,2)=NaN;x(2,1,2)=NaN;
   case 'nanup';x(1,2,2)=NaN;
   case 'nanlow';x(2,1,2)=NaN;
   case 'nanedge';x(5,4,3:7)=NaN;x(4,5,3:7)=NaN;
   case 'nanall';x(:,:,3)=NaN;
   case 'inf2';x(1,3,2)=Inf;x(3,1,2)=Inf;
   case 'ninf2';x(1,3,2)=-Inf;x(3,1,2)=-Inf;
   case 'negzero';x(1,2,3)=-0;x(2,1,3)=-0;
   case 'zero';x(3,:,4)=0;x(:,3,4)=0;
   case 'const';x(2,1,:)=0.25;x(1,2,:)=0.25;
   case 'asym';t=0.5*x(:,:,2);x(:,:,2)=triu(x(:,:,2))+tril(t,-1);
   case 'ynan';y(4)=NaN;
   case 'yinf';y(4)=Inf;
   case 'yconst';y(:)=0.5;
   case 'logical';x=x>0;
   case 'single';x=single(x);
   case 'ysingle';y=single(y);
   case 'yint16';y=int16(y*1000);
   case 'csingle';cv=single(cv);
   case 'one';x=x(:,:,1);y=y(1);if ~isempty(cv);cv=cv(1,:);end
   case 'empty';x=[];
   otherwise;error('bad mod %s',mm{1});
  end
 end
end
switch smode
 case {'col','none','mat2'}
 case 'row';y=y.';
 case 'short';y=y(1:end-1);
 otherwise;error('bad score %s',smode);
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
  otherwise;error('bad argument type %s',ty);
 end
end
end

function [A,B,C,s]=cohort(seed,N,n,nsig,ties,nb,nc)
% One statement per operation, so no two operations can be fused. nsig signal edges with
% weights +1, -1/2, +1/3, -1/4, ... in the lower-triangle order; the matrices are symmetric.
rng(seed,'twister');
ne=N*(N-1)/2;
E=rand(max(ne,nsig),n)-0.5;U=rand(n,nb)-0.5;C=rand(n,nc)-0.5;
s=E(1,:).';
for k=2:nsig
 w=1/k;if mod(k,2)==0;w=-w;end
 t=w*E(k,:).';s=s+t;
end
B=zeros(n,nb);
for m=1:nb;t=(0.2*m)*U(:,m);B(:,m)=s+t;end
if ties;B=round(B*4)/4;end
A=zeros(N,N,n);L=tril(true(N),-1);
for i=1:n
 M=zeros(N);M(L)=E(1:ne,i);M=M+M.';A(:,:,i)=M;
end
end

function s=hexwords(v)
s=strjoin(cellstr(num2hex(double(v(:)))),' ');if isempty(s);s='-';end
end

function s=hexbytes(t)
s=sprintf('%02x',uint8(char(t)));if isempty(s);s='00';end
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
