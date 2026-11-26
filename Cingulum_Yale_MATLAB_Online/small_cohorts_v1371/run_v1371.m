function run_v1371()
% V1371 SOURCE-DISCLOSED DIAGNOSTIC (not evidence for any certificate). Three parts:
% (1) Yale's own ridgeCPM and ridgeCPM_PCA (YaleMRRC/CPM b903f83, unchanged) on small synthetic
%     cohorts (cases.csv, seeds 137,100,000 + case; no V1370 case), exactly as run_v1364.m runs
%     its cases: every returned output word, sizes, errors, last warning, printed warnings, twice;
% (2) the economy QR and one-component pca of n x 2 data, n = 2..20, as run_v1363.m (kinds 0-2,
%     ten seeds each, seeds 137,150,000 + index): mean, R(1,1) R(1,2) R(2,2), loading, X*loading;
% (3) computeLambdaMax on a design with no columns and ridgeCPM's lambda sequence from it, with
%     the full error report of each step.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
yale=fullfile(root,'upstream','matlab','misc');addpath(yale);
for fn={'ridgeCPM','ridgeCPM_PCA','find_lambda','computeLambdaMax'}
 assert(strcmp(which(fn{1}),fullfile(yale,[fn{1} '.m'])),'%s is not the pinned Yale file',fn{1});
end
for fn={'lasso','crossvalind','corr','pca','squareform','rng','rand'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(lines{1},'case,func,seed,nr,nc,n,nt,kind,nb,ties,thresh,alpha,penalty,folds'));
o=[fopen(fullfile(outdir,'hidden.bin'),'w','ieee-le'),fopen(fullfile(outdir,'hidden_repeat.bin'),'w','ieee-le')];
fs=[fopen(fullfile(outdir,'hidden_status.tsv'),'w'),fopen(fullfile(outdir,'hidden_status_repeat.tsv'),'w')];
ff=[fopen(fullfile(outdir,'hidden_fields.csv'),'w'),fopen(fullfile(outdir,'hidden_fields_repeat.csv'),'w')];
fw=[fopen(fullfile(outdir,'hidden_warnings.tsv'),'w'),fopen(fullfile(outdir,'hidden_warnings_repeat.tsv'),'w')];
assert(all([o fs ff fw]>0));
words=0;nerr=0;
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',');assert(numel(f)==14);
 c=str2double(f{1});assert(c==li-2);
 func=f{2};v=str2double(f(3:10));
 seed=v(1);nr=v(2);nc=v(3);n=v(4);nt=v(5);kind=v(6);nb=v(7);ties=v(8);
 thresh=str2double(f{11});alpha=str2double(f{12});
 [A,B]=cohort(seed,nr,nc,n,nt,kind,nb,ties);
 lambda=penalty(f{13});[karg,given]=folds(f{14},n);
 for rep=1:2
  lastwarn('','');txt='';
  try
   if strcmp(func,'ridge')
    out=cell(1,8);
    txt=evalc('[out{1:8}]=ridgeCPM(A,B,thresh,alpha,lambda,karg,seed);');
    names={'q_s','q_s_fold','r_pearson','r_rank','y','beta_total','intercept_total','lambda_total'};
   else
    assert(strcmp(func,'pca'));
    out=cell(1,10);
    txt=evalc('[out{1:10}]=ridgeCPM_PCA(A,B,thresh,alpha,lambda,karg,seed);');
    names={'q_s','q_s_fold','r_pearson','r_rank','y','new_behav','pca_coef_total','coef_total','coef0_total','lambda_total'};
   end
   [lm,lid]=lastwarn;
   if given
    labels=karg;
   else
    rng(seed,'twister');labels=crossvalind('Kfold',n,karg);
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
   if rep==1;nerr=nerr+1;end
  end
  msgs=captured(txt);
  for q=1:numel(msgs);fprintf(fw(rep),'%d\t%d\t%s\n',c,q,msgs{q});end
 end
 fprintf('case %d %s %s done\n',c,func,f{14});
 clear A B out
end
fclose('all');
pca_two_small(outdir);lambda_empty(outdir);
prov=struct('classification','V1371_SOURCE_DISCLOSED_SMALL_COHORTS_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'yale_commit',getenv('YALE_COMMIT'),'forecast_read',false,'cases',numel(lines)-1,'words',words,'errors',nerr);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
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

function pca_two_small(outdir)
fh=[fopen(fullfile(outdir,'v1371_pca.bin'),'w','ieee-le'),fopen(fullfile(outdir,'v1371_pca_repeat.bin'),'w','ieee-le')];
fc=fopen(fullfile(outdir,'v1371_pca_cases.csv'),'w');fprintf(fc,'case,seed,n,kind\n');
c=0;
for n=2:20
 for kind=0:2
  for r=1:10
   seed=137150000+c;fprintf(fc,'%d,%d,%d,%d\n',c,seed,n,kind);
   for rep=1:2
    rng(seed,'twister');
    if kind==0
     X=rand(n,2)-0.5;
    else
     U=rand(n,2)-0.5;X=zeros(n,2);t=0.6*U(:,1);X(:,2)=t+U(:,2);X(:,1)=U(:,1);
     if kind==2;X=round(X*4)/4;end
    end
    mu=mean(X,1);C=X-mu;[~,R]=qr(C,0);
    loading=pca(X,'NumComponents',1);proj=X*loading;
    w=[mu(:);R(1,1);R(1,2);R(2,2);numel(loading);loading(:);proj(:)];
    fwrite(fh(rep),typecast(w,'uint64'),'uint64');
   end
   c=c+1;
  end
 end
end
fclose(fh(1));fclose(fh(2));fclose(fc);
end

function lambda_empty(outdir)
h=fopen(fullfile(outdir,'lambda_empty.txt'),'w');
rng(137199999,'twister');y=rand(10,1)-0.5;X=zeros(10,0);
try
 [lm,nm]=computeLambdaMax(X,y,[],0.01,true);
 fprintf(h,'computeLambdaMax returned: lambdaMax %dx%d %s, nullMSE %dx%d %s\n',size(lm),hexwords(lm),size(nm),hexwords(nm));
 lmin=lm*0.001;loghi=log(lm);loglo=log(lmin);
 fprintf(h,'lmin %dx%d, loghi %dx%d, loglo %dx%d\n',size(lmin),size(loghi),size(loglo));
 try
  s=exp(linspace(loghi,loglo,16));
  fprintf(h,'sequence %dx%d %s\n',size(s),hexwords(s));
 catch e
  fprintf(h,'linspace error id=%s\n%s\n',e.identifier,e.getReport('extended','hyperlinks','off'));
 end
catch e
 fprintf(h,'computeLambdaMax error id=%s\n%s\n',e.identifier,e.getReport('extended','hyperlinks','off'));
end
fclose(h);
end

function s=hexwords(x)
s=strjoin(arrayfun(@(u)sprintf('%016x',u),typecast(double(x(:)),'uint64'),'UniformOutput',false),' ');
if isempty(s);s='[]';end
end
