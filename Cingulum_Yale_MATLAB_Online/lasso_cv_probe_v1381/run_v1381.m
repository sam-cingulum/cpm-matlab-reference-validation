function run_v1381()
% V1381 SOURCE-DISCLOSED DIAGNOSTIC (not evidence for any certificate). Two parts:
% (1) Yale's own ridgeCPM_PCA and ridgeCPM (YaleMRRC/CPM b903f83, unchanged) called with the
%     first nargs of (all_mats, all_behav, thresh, v_alpha, lambda, k, seed) (cases.csv, seeds
%     138,100,000 + case; no earlier case): lambda omitted (lasso 'CV' 10 in every fold), v_alpha
%     omitted or [], lambda = [], k omitted or []. Every returned output word, sizes, errors with
%     their stack, last warning and printed warnings, twice, as run_v1376.m does;
% (2) MATLAB's own lasso(X, y, 'Alpha', a, 'CV', 10) of n x p twister data (lasso_cases.csv,
%     seeds 138,150,000 + case; rng(seed,'twister') again right before the call): B, every
%     FitInfo field, the cvpartition labels and four draws after the call, twice.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
yale=fullfile(root,'upstream','matlab','misc');addpath(yale);
for fn={'ridgeCPM','ridgeCPM_PCA','find_lambda','computeLambdaMax'}
 assert(strcmp(which(fn{1}),fullfile(yale,[fn{1} '.m'])),'%s is not the pinned Yale file',fn{1});
end
for fn={'lasso','crossvalind','cvpartition','corr','pca','squareform','rng','rand'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lasso_part(root,outdir);
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(lines{1},'case,func,seed,nr,nc,n,nt,kind,nb,ties,thresh,alpha,penalty,folds,nargs'));
o=[fopen(fullfile(outdir,'hidden.bin'),'w','ieee-le'),fopen(fullfile(outdir,'hidden_repeat.bin'),'w','ieee-le')];
fs=[fopen(fullfile(outdir,'hidden_status.tsv'),'w'),fopen(fullfile(outdir,'hidden_status_repeat.tsv'),'w')];
ff=[fopen(fullfile(outdir,'hidden_fields.csv'),'w'),fopen(fullfile(outdir,'hidden_fields_repeat.csv'),'w')];
fw=[fopen(fullfile(outdir,'hidden_warnings.tsv'),'w'),fopen(fullfile(outdir,'hidden_warnings_repeat.tsv'),'w')];
fk=fopen(fullfile(outdir,'hidden_stack.tsv'),'w');
assert(all([o fs ff fw fk]>0));
words=0;nerr=0;
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',');assert(numel(f)==15);
 c=str2double(f{1});assert(c==li-2);
 func=f{2};v=str2double(f(3:10));
 seed=v(1);nr=v(2);nc=v(3);n=v(4);nt=v(5);kind=v(6);nb=v(7);ties=v(8);
 thresh=str2double(f{11});nargs=str2double(f{15});
 [A,B]=cohort(seed,nr,nc,n,nt,kind,nb,ties);
 if strcmp(f{12},'empty');alpha=[];elseif strcmp(f{12},'omit');alpha=NaN;assert(nargs<4);else;alpha=str2double(f{12});end
 if any(strcmp(f{13},{'omit','auto'}));lambda=[];assert(strcmp(f{13},'auto')||nargs<5);else;lambda=penalty(f{13});end
 if strcmp(f{14},'empty');karg=[];given=false;elseif strcmp(f{14},'omit');karg=10;given=false;assert(nargs<6);else;[karg,given]=folds(f{14},n);end
 args={A,B,thresh,alpha,lambda,karg,seed};args=args(1:nargs); %#ok<NASGU>
 % The labels Yale draws under its own default rules (k 10 and seed 665 when omitted;
 % ridgeCPM_PCA also resets seed to 665 when v_alpha is not a scalar).
 seff=seed;
 if nargs<7||(strcmp(func,'pca')&&numel(alpha)~=1);seff=665;end
 for rep=1:2
  lastwarn('','');txt='';
  try
   if strcmp(func,'ridge')
    out=cell(1,8);
    txt=evalc('[out{1:8}]=ridgeCPM(args{:});');
    names={'q_s','q_s_fold','r_pearson','r_rank','y','beta_total','intercept_total','lambda_total'};
   else
    assert(strcmp(func,'pca'));
    out=cell(1,10);
    txt=evalc('[out{1:10}]=ridgeCPM_PCA(args{:});');
    names={'q_s','q_s_fold','r_pearson','r_rank','y','new_behav','pca_coef_total','coef_total','coef0_total','lambda_total'};
   end
   [lm,lid]=lastwarn;
   if given
    labels=karg;
   else
    rng(seff,'twister');labels=crossvalind('Kfold',n,karg);
   end
   out{end+1}=labels;names{end+1}='labels'; %#ok<AGROW>
   for q=1:numel(out)
    x=out{q};[r,k]=size(x);
    w=typecast(double(x(:)),'uint64');fwrite(o(rep),w,'uint64');
    fprintf(ff(rep),'%d,%s,%d,%d\n',c,names{q},r,k);
    if rep==1;words=words+numel(w);end
   end
   fprintf(fs(rep),'%d\treturned\t-\t-\t%s\t%s\n',c,dash(lid),dash(lm));
  catch e
   fprintf(fs(rep),'%d\terror\t%s\t%s\t-\t-\n',c,dash(e.identifier),dash(e.message));
   if rep==1;nerr=nerr+1;
    for s=1:numel(e.stack);fprintf(fk,'%d\t%d\t%s\t%s\t%d\n',c,s,dash(e.stack(s).file),dash(e.stack(s).name),e.stack(s).line);end
   end
  end
  msgs=captured(txt);
  for q=1:numel(msgs);fprintf(fw(rep),'%d\t%d\t%s\n',c,q,msgs{q});end
 end
 fprintf('case %d %s nargs %d done\n',c,func,nargs);
 clear A B out args
end
fclose('all');
prov=struct('classification','V1381_SOURCE_DISCLOSED_LASSO_CV_PROBE_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'yale_commit',getenv('YALE_COMMIT'),'forecast_read',false,'cases',numel(lines)-1,'words',words,'errors',nerr);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function lasso_part(root,outdir)
lines=strsplit(strtrim(fileread(fullfile(root,'lasso_cases.csv'))),newline);
assert(strcmp(lines{1},'case,seed,n,p,kind,alpha'));
fh=[fopen(fullfile(outdir,'lasso.bin'),'w','ieee-le'),fopen(fullfile(outdir,'lasso_repeat.bin'),'w','ieee-le')];
fs=[fopen(fullfile(outdir,'lasso_status.tsv'),'w'),fopen(fullfile(outdir,'lasso_status_repeat.tsv'),'w')];
assert(all([fh fs]>0));
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',');assert(numel(f)==6);
 v=str2double(f(1:5));assert(v(1)==li-2);
 c=v(1);seed=v(2);n=v(3);p=v(4);kind=v(5);a=str2double(f{6});
 for rep=1:2
  [X,y]=lassodata(seed,n,p,kind);
  lastwarn('','');txt='';
  try
   rng(seed,'twister');
   txt=evalc('[Bc,FI]=lasso(X,y,''Alpha'',a,''CV'',10);');
   nxt=rand(4,1);
   [lm,lid]=lastwarn;
   rng(seed,'twister');cp=cvpartition(n,'KFold',10);lab=zeros(n,1);
   for t=1:cp.NumTestSets;lab(cp.test(t))=t;end
   L=numel(FI.Lambda);
   w=[n;p;size(Bc,1);size(Bc,2);Bc(:);L;FI.Lambda(:);FI.Intercept(:);FI.MSE(:);FI.SE(:);FI.DF(:); ...
      FI.IndexMinMSE;FI.Index1SE;FI.LambdaMinMSE;FI.Lambda1SE;FI.Alpha;lab;nxt];
   fwrite(fh(rep),typecast(w,'uint64'),'uint64');
   fprintf(fs(rep),'%d\treturned\t%d\t%d\t%s\t%s\n',c,numel(w),L,dash(lid),dash(lm));
  catch e
   fprintf(fs(rep),'%d\terror\t%s\t%s\t-\t-\n',c,dash(e.identifier),dash(e.message));
  end
  msgs=captured(txt);
  for q=1:numel(msgs);fprintf(fs(rep),'%d\twarning\t%d\t%s\n',c,q,msgs{q});end
 end
 fprintf('lasso case %d n %d p %d done\n',c,n,p);
end
fclose('all');
end

function [X,y]=lassodata(seed,n,p,kind)
% One statement per operation, so no two operations can be fused.
rng(seed,'twister');
X=rand(n,p)-0.5;e=rand(n,1)-0.5;
switch kind
 case 0
 case 1;X=round(X*4)/4;
 case 2;X(:,mod(seed,p)+1)=0;
 case 3;X(:,p)=X(:,1);
 case 4
  for j=1:p;t=10^(mod(j,5)-2);X(:,j)=t*X(:,j);end
 otherwise;error('bad kind %d',kind);
end
y=X(:,1);t=0.5*X(:,min(2,p));y=y-t;t=0.3*e;y=y+t;
if kind==1;y=round(y*4)/4;end
end

function [A,B]=cohort(seed,nr,nc,n,nt,kind,nb,ties)
% One statement per operation, so no two operations can be fused.
rng(seed,'twister');
if kind==1;ne=nr*nc;else;ne=nr*(nr-1)/2;end
E=rand(ne*nt,n)-0.5;U=rand(n,nb)-0.5;
s=E(1,:).';t=0.5*E(2,:).';s=s-t;t=0.25*E(3,:).';s=s+t;
B=zeros(n,nb);
for m=1:nb;t=(0.2*m)*U(:,m);B(:,m)=s+t;end
if ties;B=round(B*4)/4;end
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

function lambda=penalty(text)
if strcmp(text,'auto');lambda=[];
elseif startsWith(text,'fixed:');lambda=str2double(text(7:end));
elseif startsWith(text,'grid:');lambda=str2double(strsplit(text(6:end),';'));
else;error('bad penalty %s',text);end
end

function [karg,given]=folds(text,n)
p=strsplit(text,':');q=0;if numel(p)>1;q=str2double(p{2});end
given=true;
switch p{1}
 case 'kfold';karg=q;given=false;
 case 'loo';karg=n;given=false;
 case 'cyc';karg=mod((0:n-1)',q)+1;
 case 'gap';karg=mod((0:n-1)',q)+1;karg(karg==2)=q+1;
 case 'badlen';karg=mod((0:n-2)',q)+1;
 otherwise;error('bad folds %s',text);
end
end

function s=dash(s)
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end

function msgs=captured(txt)
% The warnings evalc captured, in order, with MATLAB's display wrapping undone.
txt=strrep(txt,char(8),'');
tok=regexp(txt,'\[Warning: (.*?)\] ?\n','tokens');
msgs=cellfun(@(c)strrep(c{1},newline,' '),tok,'UniformOutput',false);
end


