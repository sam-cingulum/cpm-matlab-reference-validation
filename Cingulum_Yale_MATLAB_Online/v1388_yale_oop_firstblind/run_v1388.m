function run_v1388()
% V1388 original-only firstblind: Yale's own OOP classes cpm, rcpm and cross (YaleMRRC/CPM b903f83,
% matlab/oop, unchanged) with the options structs a caller can pass (cases.csv:
% case,cls,seed,nr,nc,n,nt,kind,nb,ties,n1,opts, an earlier probe's grammar on fresh cohorts, to
% 268 nodes and 1,200 subjects). Each cohort is generated with MATLAB's own generator (cohort
% below; V1386's generator). For each case, twice: the stage and the error (identifier and text)
% when Yale errors; otherwise every public property the class leaves (Y, coef_total,
% coef0_total, lambda_total, q_s, r_pearson, r_rank, mse) with MATLAB's size, one draw after
% evaluate, the printed text of run and of evaluate, and the last warning.
% No MEX, no twin, no Rust forecast, no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
oop=fullfile(root,'upstream','matlab','oop');addpath(oop);
for fn={'cpm','rcpm','cross','predictory','group','subject','phenotype'}
 assert(strcmp(which(fn{1}),fullfile(oop,[fn{1} '.m'])),'%s is not the pinned Yale file',fn{1});
end
for fn={'lasso','cvpartition','corr','partialcorr','polyfit','squareform','rng','rand','var'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(lines{1},'case,cls,seed,nr,nc,n,nt,kind,nb,ties,n1,opts'));
o=[fopen(fullfile(outdir,'oop.bin'),'w','ieee-le'),fopen(fullfile(outdir,'oop_repeat.bin'),'w','ieee-le')];
fs=[fopen(fullfile(outdir,'oop_status.tsv'),'w'),fopen(fullfile(outdir,'oop_status_repeat.tsv'),'w')];
ff=[fopen(fullfile(outdir,'oop_fields.csv'),'w'),fopen(fullfile(outdir,'oop_fields_repeat.csv'),'w')];
ft=[fopen(fullfile(outdir,'oop_text.tsv'),'w'),fopen(fullfile(outdir,'oop_text_repeat.tsv'),'w')];
fk=fopen(fullfile(outdir,'oop_stack.tsv'),'w');ftime=fopen(fullfile(outdir,'oop_seconds.tsv'),'w');
assert(all([o fs ff ft fk ftime]>0));
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',');assert(numel(f)==12);
 c=str2double(f{1});assert(c==li-2);
 cls=f{2};v=str2double(f(3:11));
 seed=v(1);nr=v(2);nc=v(3);n=v(4);nt=v(5);kind=v(6);nb=v(7);ties=v(8);n1=v(9);
 for rep=1:2
  t0=tic;stage='cohort';txtrun='';txteval='';
  lastwarn('','');
  try
   [A,B]=cohort(seed,nr,nc,n,nt,kind,nb,ties);C=controls(seed,n);
   stage='group';
   if strcmp(cls,'cross')
    g1=buildgroup(A,1:n1);g2=buildgroup(A,n1+1:n);
    p1=phenotype("synthetic",B(1:n1,:));p2=phenotype("synthetic",B(n1+1:n,:));
    opts=options(f{12},C,p1,p1,p2);
    stage='construct';obj=cross(g1,g2,opts);
   else
    g=buildgroup(A,1:n);p=phenotype("synthetic",B);
    opts=options(f{12},C,p,p,p);
    stage='construct';
    if strcmp(cls,'cpm');obj=cpm(g,opts);else;assert(strcmp(cls,'rcpm'));obj=rcpm(g,opts);end
   end
   clear A
   stage='run';rng(seed,'twister');
   txtrun=evalc('obj.run();');
   stage='evaluate';
   txteval=evalc('obj.evaluate();');
   nxt=rand;
   [lm,lid]=lastwarn;
   names={'Y','coef_total','coef0_total','lambda_total','q_s','r_pearson','r_rank','mse','next'};
   vals={obj.Y,obj.coef_total,obj.coef0_total,obj.lambda_total,obj.q_s,obj.r_pearson,obj.r_rank,obj.mse,nxt};
   for q=1:numel(vals)
    x=vals{q};[r,k]=size(x);
    fwrite(o(rep),typecast(double(x(:)),'uint64'),'uint64');
    fprintf(ff(rep),'%d,%s,%d,%d,%s\n',c,names{q},r,k,class(x));
   end
   fprintf(fs(rep),'%d\treturned\t-\t-\t-\t%s\t%s\n',c,dash(lid),dash(lm));
  catch e
   [lm,lid]=lastwarn;
   fprintf(fs(rep),'%d\terror\t%s\t%s\t%s\t%s\t%s\n',c,stage,dash(e.identifier),dash(e.message),dash(lid),dash(lm));
   if rep==1
    for s=1:numel(e.stack);fprintf(fk,'%d\t%d\t%s\t%s\t%d\n',c,s,dash(e.stack(s).name),dash(e.stack(s).file),e.stack(s).line);end
   end
  end
  fprintf(ft(rep),'%d\trun\t%s\n',c,hexbytes(txtrun));
  fprintf(ft(rep),'%d\tevaluate\t%s\n',c,hexbytes(txteval));
  if rep==1;fprintf(ftime,'%d\t%.3f\n',c,toc(t0));end
  clear obj g g1 g2 p p1 p2 opts B C A
 end
 fprintf('case %d %s done\n',c,cls);
end
fclose('all');
prov=struct('classification','V1388_ORIGINAL_ONLY_YALE_OOP_FIRSTBLIND','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'yale_commit',getenv('YALE_COMMIT'),'forecast_read',false,'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function g=buildgroup(A,idx)
subs(1,numel(idx))=subject;
for i=1:numel(idx)
 subs(i)=subject(A(:,:,idx(i),:),idx(i),"synthetic","none");
end
g=group(subs);
end

function opts=options(spec,C,p,p1,p2)
opts=struct();
if isempty(spec);return;end
items=strsplit(spec,'|');
for i=1:numel(items)
 kv=strsplit(items{i},'=');assert(numel(kv)==2);key=kv{1};val=kv{2};
 switch key
  case 'control'
   switch val
    case 'empty';x=[];
    case 'c1';x=C(:,1);
    case 'c2';x=C;
    case 'c1short';x=C(1:end-1,1);
    case 'c1row';x=C(:,1).';
    otherwise;error('bad control %s',val);
   end
  case 'phenotype';x=p;
  case 'phenotype1';x=p1;
  case 'phenotype2';x=p2;
  case 'model';x=string(val);
  case {'k','seed','thresh','v_alpha','taskID1','taskID2'};x=str2double(val);
  case 'lambda';x=str2double(strsplit(val,';'));
  otherwise;error('bad option %s',key);
 end
 opts.(key)=x;
end
end

function [A,B]=cohort(seed,nr,nc,n,nt,kind,nb,ties)
% One statement per operation, so no two operations can be fused (V1386's generator).
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

function C=controls(seed,n)
rng(seed+500000,'twister');
C=rand(n,2)-0.5;
end

function s=hexbytes(t)
s=sprintf('%02x',uint8(char(t)));if isempty(s);s='-';end
end

function s=dash(s)
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end
