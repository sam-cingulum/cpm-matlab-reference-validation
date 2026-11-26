function run_v1369()
% V1369 source-disclosed diagnostic (retrospective, after the V1364 FAIL; certifies nothing).
% Reruns V1364 cases 65, 66, 69, 72 and 77 with unchanged Yale code and the V1364 case list,
% once each, under diary (Yale prints numel(edges_1) per fold) and records getReport of any
% error with its stack, to find the line where case 77 raises MATLAB:sizeDimensionsMustMatch.
% Then calls lasso with zero predictors. V12 SEALED.
% V1364 original-only firstblind: Yale's own ridgeCPM and ridgeCPM_PCA (YaleMRRC/CPM b903f83,
% unchanged) on fresh synthetic cohorts. Reads the frozen case list only
% (cases.csv: case,func,seed,nr,nc,n,nt,kind,nb,ties,thresh,alpha,penalty,folds), regenerates
% each cohort with MATLAB's own generator (see cohort below), calls the Yale function twice per
% case and writes every returned output word for word, MATLAB's size of each output, the error
% (identifier and text) when Yale errors, the last warning (lastwarn) and every warning the call
% printed. For generated folds the labels are rebuilt independently with the same seed
% (rng(seed,'twister'); crossvalind('Kfold',n,k)). No MEX, no twin, no Rust forecast, no
% earlier MATLAB output.
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
 if ~ismember(c,[65 66 69 72 77]);continue;end
 func=f{2};v=str2double(f(3:10));
 seed=v(1);nr=v(2);nc=v(3);n=v(4);nt=v(5);kind=v(6);nb=v(7);ties=v(8);
 thresh=str2double(f{11});alpha=str2double(f{12});
 [A,B]=cohort(seed,nr,nc,n,nt,kind,nb,ties);
 lambda=penalty(f{13});[karg,given]=folds(f{14},n);
 for rep=1
 diary(fullfile(outdir,sprintf('diary_case%d.txt',c)));
  lastwarn('','');txt='';
  try
   if strcmp(func,'ridge')
    out=cell(1,8);
    [out{1:8}]=ridgeCPM(A,B,thresh,alpha,lambda,karg,seed);
    names={'q_s','q_s_fold','r_pearson','r_rank','y','beta_total','intercept_total','lambda_total'};
   else
    assert(strcmp(func,'pca'));
    out=cell(1,10);
    [out{1:10}]=ridgeCPM_PCA(A,B,thresh,alpha,lambda,karg,seed);
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
   hr=fopen(fullfile(outdir,sprintf('report_case%d.txt',c)),'w');fprintf(hr,'%s\n',getReport(e,'extended','hyperlinks','off'));fclose(hr);
  end
  diary off;
  msgs=captured(txt);
  for q=1:numel(msgs);fprintf(fw(rep),'%d\t%d\t%s\n',c,q,msgs{q});end
 end
 fprintf('case %d %s %s done\n',c,func,f{14});
 clear A B out
end
fclose('all');
hl=fopen(fullfile(outdir,'lasso_empty.txt'),'w');
rng(136900000,'twister');X=zeros(10,0);y=rand(10,1);
lams={[0.4 0.1 0.03],0.05};
for q=1:2
 try
  [Bq,FI]=lasso(X,y,'Alpha',1e-6,'Lambda',lams{q});
  fprintf(hl,'lambda %d returned: B %dx%d, MSE %s, Intercept %s\n',q,size(Bq,1),size(Bq,2),mat2str(FI.MSE,17),mat2str(FI.Intercept,17));
 catch e
  fprintf(hl,'lambda %d error %s: %s\n%s\n',q,e.identifier,e.message,getReport(e,'extended','hyperlinks','off'));
 end
end
fclose(hl);
prov=struct('classification','V1369_SOURCE_DISCLOSED_CASE77_DIAGNOSTIC','V12','SEALED', ...
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
