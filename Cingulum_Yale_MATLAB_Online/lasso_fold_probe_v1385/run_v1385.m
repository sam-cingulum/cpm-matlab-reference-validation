function run_v1385()
% V1385 SOURCE-DISCLOSED DIAGNOSTIC (not evidence for any certificate): MATLAB's own lasso fits
% of each ten-fold cross-validation training set, for designs shaped like the two V1384 lasso
% misses. Cases 0 and 1 replicate V1384 lasso cases 26 and 50 (already scored, FAIL on record);
% every other case uses new seeds 138,500,000 + case. For each case: lasso(X,y,'Alpha',a,'CV',10)
% after rng(seed,'twister'); the same data with 'Lambda' set to the kept grid, to a 100-point
% grid, and with no 'Lambda'; then, for each fold of cvpartition(n,'KFold',10) drawn after
% rng(seed,'twister'), lasso of the fold's training rows with 'Lambda' the kept grid, with
% 'UseCovariance' left out, true and false; 'sweep' cases add 'MaxIter' 1..15, 25, 50, 100, 1000.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'lasso','cvpartition','rng','rand'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'lasso_cases.csv'))),newline);
assert(strcmp(lines{1},'case,seed,n,p,kind,alpha,mode'));
fh=[fopen(fullfile(outdir,'folds.bin'),'w','ieee-le'),fopen(fullfile(outdir,'folds_repeat.bin'),'w','ieee-le')];
fs=[fopen(fullfile(outdir,'folds_status.tsv'),'w'),fopen(fullfile(outdir,'folds_status_repeat.tsv'),'w')];
assert(all([fh fs]>0));
nrec=0;
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',');assert(numel(f)==7);mode=f{7};
 v=str2double(f(1:5));assert(v(1)==li-2);
 c=v(1);seed=v(2);n=v(3);p=v(4);kind=v(5);a=str2double(f{6});
 for rep=1:2
  [X,y]=lassodata(seed,n,p,kind);
  rng(seed,'twister');
  G=call(fh(rep),fs(rep),c,0,0,0,@()lasso(X,y,'Alpha',a,'CV',10));
  if rep==1;nrec=nrec+1;end
  call(fh(rep),fs(rep),c,0,3,0,@()lasso(X,y,'Alpha',a));
  if isempty(G);continue;end
  call(fh(rep),fs(rep),c,0,1,0,@()lasso(X,y,'Alpha',a,'Lambda',G));
  top=G(end);Lfull=exp(linspace(log(top*1e-4),log(top),100));
  call(fh(rep),fs(rep),c,0,2,0,@()lasso(X,y,'Alpha',a,'Lambda',Lfull));
  rng(seed,'twister');cp=cvpartition(n,'KFold',10);lab=zeros(n,1);
  for t=1:cp.NumTestSets;lab(cp.test(t))=t;end
  fwrite(fh(rep),typecast([c;0;9;0;n;lab],'uint64'),'uint64');
  inherit=n>p;
  for k=1:cp.NumTestSets
   tr=cp.training(k);Xt=X(tr,:);yt=y(tr);
   call(fh(rep),fs(rep),c,k,10,0,@()lasso(Xt,yt,'Alpha',a,'Lambda',G));
   okT=~isempty(call(fh(rep),fs(rep),c,k,11,0,@()lasso(Xt,yt,'Alpha',a,'Lambda',G,'UseCovariance',true)));
   call(fh(rep),fs(rep),c,k,12,0,@()lasso(Xt,yt,'Alpha',a,'Lambda',G,'UseCovariance',false));
   if strcmp(mode,'sweep')
    for m=[1:15 25 50 100 1000]
     if okT
      call(fh(rep),fs(rep),c,k,20,m,@()lasso(Xt,yt,'Alpha',a,'Lambda',G,'UseCovariance',inherit,'MaxIter',m));
     else
      call(fh(rep),fs(rep),c,k,21,m,@()lasso(Xt,yt,'Alpha',a,'Lambda',G,'MaxIter',m));
     end
    end
   end
  end
 end
 fprintf('lasso fold case %d n %d p %d %s done\n',c,n,p,mode);
end
fclose('all');
prov=struct('classification','V1385_SOURCE_DISCLOSED_LASSO_FOLD_PROBE_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false,'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function G=call(fh,fs,c,k,variant,m,fn)
% One lasso call: a record [c;k;variant;m;status;...] and one status line. On success the
% record holds size(B), B(:), then FitInfo's Lambda, Intercept, MSE, DF (each with its length),
% SE (with its length), IndexMinMSE and Index1SE (NaN when empty), and the warning count.
% G is the returned FitInfo.Lambda (empty on an error).
G=[];lastwarn('','');txt='';
try
 txt=evalc('[B,FI]=fn();');
 [lm,lid]=lastwarn;msgs=captured(txt);
 w=[c;k;variant;m;0;size(B,1);size(B,2);B(:)];
 for nm={'Lambda','Intercept','MSE','DF','SE'}
  q=field(FI,nm{1});w=[w;numel(q);double(q(:))]; %#ok<AGROW>
 end
 w=[w;nanempty(field(FI,'IndexMinMSE'));nanempty(field(FI,'Index1SE'));numel(msgs)];
 fwrite(fh,typecast(w,'uint64'),'uint64');
 first='-';if ~isempty(msgs);first=msgs{1};end
 fprintf(fs,'%d\t%d\t%d\t%d\treturned\t%d\t%s\t%s\t%d\t%s\n',c,k,variant,m,numel(w),dash(lid),dash(lm),numel(msgs),dash(first));
 G=FI.Lambda;
catch e
 msgs=captured(txt);
 fwrite(fh,typecast([c;k;variant;m;1;numel(msgs)],'uint64'),'uint64');
 fprintf(fs,'%d\t%d\t%d\t%d\terror\t6\t%s\t%s\t%d\t-\n',c,k,variant,m,dash(e.identifier),dash(e.message),numel(msgs));
end
end

function q=field(FI,name)
% A FitInfo field, or empty when lasso did not return it (no 'CV').
if isfield(FI,name);q=FI.(name);else;q=[];end
end

function v=nanempty(x)
if isempty(x);v=NaN;else;v=double(x);end
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

function s=dash(s)
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end

function msgs=captured(txt)
% The warnings evalc captured, in order, with MATLAB's display wrapping undone.
txt=strrep(txt,char(8),'');
tok=regexp(txt,'\[Warning: (.*?)\] ?\n','tokens');
msgs=cellfun(@(c)strrep(c{1},newline,' '),tok,'UniformOutput',false);
end
