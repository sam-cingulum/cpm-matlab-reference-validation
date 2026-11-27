function run_v1400()
% V1400 SOURCE-DISCLOSED diagnostic: single/mixed arithmetic for the OHBM kfold case 125.
% No MathWorks source or internals are read. Synthetic inputs only; not a certificate.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
fo=[fopen(fullfile(outdir,'single.bin'),'w','ieee-le'),fopen(fullfile(outdir,'single_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'single_fields.csv'),'w'),fopen(fullfile(outdir,'single_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'single_status.tsv'),'w'),fopen(fullfile(outdir,'single_status_repeat.tsv'),'w')];
assert(all(fo>0)&&all(ff>0)&&all(fs>0));
for rep=1:2
S=struct('fo',fo(rep),'ff',ff(rep),'fs',fs(rep),'serial',0,'context','');
S.context='A: exact V1392 case 125 generator';
[x,y]=cohort125();ys=single(y);
S=dump(S,'X_double',x);S=dump(S,'y_double',y);S=dump(S,'y_single',ys);
N=size(x,1);ns=size(x,3);m=reshape(x,N*N,ns);
up=find(triu(ones(N,N),1)>0);
S=dump(S,'upper_zero_based',double(up-1));
rng(139200125,'twister');ord=randperm(ns);pf=round(ns/5);
S=dump(S,'permutation_zero_based',double(ord-1));
S=dump(S,'rand_after_permutation',rand);
allpred=zeros(ns,1);
for fold=1:5
 cf=ord((fold-1)*pf+1:min(fold*pf,ns));
 tr=m(up,:);tr(:,cf)=[];ts=ys;ts(cf)=[];
 test=m(up,cf);
 S.context=sprintf('A fold %d',fold);
 S=dump(S,'held_out_zero_based',double(cf(:)-1));
 S=dump(S,'train_edges_double',tr.');
 S=dump(S,'train_score_single',ts);
 [r,p]=corr(tr.',ts);S=dump(S,'corr_r',r);S=dump(S,'corr_p',p);
 pe=find(r>0&p<0.05);ne=find(r<0&p<0.05);
 S=dump(S,'positive_zero_based',double(pe-1));S=dump(S,'negative_zero_based',double(ne-1));
 sp=sum(tr(pe,:));sn=sum(tr(ne,:));
 S=dump(S,'train_sum_positive',sp);S=dump(S,'train_sum_negative',sn);
 design=[sp.',sn.',ones(size(tr,2),1)];
 S=dump(S,'design_double',design);
 b=regress(ts,design);S=dump(S,'regress_b',b);
 [Q,R,perm]=qr(design,0);S=dump(S,'qr_Q',Q);S=dump(S,'qr_R',R);S=dump(S,'qr_perm',double(perm(:)));
 S=op(S,'qr_Q_transpose_times_y_single',@() Q.'*ts);
 S=op(S,'qr_Q_transpose_times_y_double',@() Q.'*double(ts));
 S=op(S,'qr_R_backslash_y_single',@() R\ts);
 S=op(S,'qr_R_backslash_y_double',@() R\double(ts));
 S=op(S,'design_backslash_y_single',@() design\ts);
 S=op(S,'design_backslash_y_double',@() design\double(ts));
 S=op(S,'single_Q_times_y_single',@() single(Q).'*ts);
 S=op(S,'single_R_backslash_y_single',@() single(R)\ts);
 S=op(S,'regress_double_y',@() regress(double(ts),design));
 S=op(S,'regress_rounded_double_y',@() regress(double(regress(ts,design)),design));
 S=op(S,'qr_Q3_transpose_times_y_single',@() Q(:,1:3).'*ts);
 S=op(S,'qr_Q3_transpose_times_y_double',@() Q(:,1:3).'*double(ts));
 S=op(S,'qr_Q3_backslash_y_single',@() Q(:,1:3)\ts);
 S=op(S,'qr_Q3_backslash_y_double',@() Q(:,1:3)\double(ts));
 S=op(S,'solve_R_Qt_single',@() R(1:3,1:3)\(Q(:,1:3).'*ts));
 S=op(S,'solve_R_Qt_double',@() R(1:3,1:3)\(Q(:,1:3).'*double(ts)));
 S=op(S,'inverse_R_Qt_single',@() inv(R(1:3,1:3))*(Q(:,1:3).'*ts));
 S=op(S,'inverse_R_Qt_double',@() inv(R(1:3,1:3))*(Q(:,1:3).'*double(ts)));
 S=op(S,'single_Q3_times_y_single',@() single(Q(:,1:3)).'*ts);
 S=op(S,'single_R3_backslash_single_Qty',@() single(R(1:3,1:3))\(single(Q(:,1:3)).'*ts));
 S=op(S,'test_sum_positive',@() sum(test(pe,:)));
 S=op(S,'test_sum_negative',@() sum(test(ne,:)));
 testdesign=[sum(test(pe,:)).',sum(test(ne,:)).',ones(numel(cf),1)];
 pred=testdesign*b;S=dump(S,'test_design',testdesign);S=dump(S,'prediction',pred);
 allpred(cf)=pred;
end
S=dump(S,'y_single_unchanged',ys);
S.context='A final correlation';
[fr,fp]=corr(allpred,ys);S=dump(S,'final_prediction',allpred);S=dump(S,'final_r',fr);S=dump(S,'final_p',fp);

% Exact first-fold designs for the three V1392 single cases that error in concatenation.
for cc=[37 124 140 125]
 S.context=sprintf('B V1392 case %d first fold',cc);
 [xx,yy,cv,partial]=caseerror(cc);
 NN=size(xx,1);nsub=size(xx,3);mm=reshape(xx,NN*NN,nsub);
 uu=find(triu(ones(NN,NN),1)>0);rng(str2double(sprintf('139200%d',cc)),'twister');
 oo=randperm(nsub);hold=oo(1:8);tt=mm(uu,:);tt(:,hold)=[];ss=yy;ss(hold)=[];
 S=dump(S,'matrix',xx);S=dump(S,'score',yy);S=dump(S,'covariate',cv);
 S=dump(S,'training_edges',tt.');S=dump(S,'training_score',ss);
 try
  if partial
   z=cv;if size(cv,2)>1;z(hold,:)=[];else;z(hold)=[];end
   [rr,pp]=partialcorr(tt.',ss,z);
  else
   [rr,pp]=corr(tt.',ss);
  end
  S=dump(S,'r',rr);S=dump(S,'p',pp);
  ep=find(rr>0&pp<0.05);en=find(rr<0&pp<0.05);
  S=dump(S,'positive_zero_based',double(ep-1));S=dump(S,'negative_zero_based',double(en-1));
  spp=sum(tt(ep,:));snn=sum(tt(en,:));
  S=dump(S,'sum_positive',spp);S=dump(S,'sum_negative',snn);
  dd=[spp.',snn.',ones(size(tt,2),1)];S=dump(S,'training_design',dd);
 catch ME
  fprintf(S.fs,'%s\tmatlab_error\t%s\t%s\n',S.context,clean(ME.identifier),clean(ME.message));
 end
end

% Independent length and shape sweep; every operation records class and raw words.
for n=[1 2 3 4 5 7 8 9 15 16 17 31 32 33 47 63 64 65 100 257]
 rng(140000000+n,'twister');
 a=single(rand(n,1)-0.5);b=single(rand(n,4)-0.5);ad=double(a);bd=double(b);
 S.context=sprintf('C length %d',n);
 S=dump(S,'a_single',a);S=dump(S,'B_single',b);
 S=op(S,'sum_a_single',@() sum(a));S=op(S,'sum_B_single',@() sum(b));
 S=op(S,'mean_a_single',@() mean(a));S=op(S,'dot_a_a_single',@() dot(a,a));
 S=op(S,'single_plus_double',@() a+ad);S=op(S,'single_times_double',@() a.*ad);
 S=op(S,'single_matrix_times_double_vector',@() b*ad);
 S=op(S,'double_matrix_times_single_vector',@() bd*a);
 S=op(S,'single_transpose_double_matrix',@() a.'*bd);
 S=op(S,'double_transpose_single_matrix',@() ad.'*b);
 S=op(S,'single_dot_double',@() dot(a,ad));S=op(S,'double_dot_single',@() dot(ad,a));
 S=op(S,'corr_double_single',@() corr(bd,a));S=op(S,'corr_single_double',@() corr(b,ad));
 S=op(S,'corr_single_single',@() corr(b,a));
 if n>=4
  S=op(S,'regress_single_y_double_X',@() regress(a,bd));
  S=op(S,'regress_double_y_single_X',@() regress(ad,b));
  S=op(S,'regress_single_single',@() regress(a,b));
  S=op(S,'double_backslash_single',@() bd\a);
  S=op(S,'single_backslash_double',@() b\ad);
  S=op(S,'single_backslash_single',@() b\a);
 end
end

% Deliberate cancellation, signed zero, scaling and degenerate QR contexts.
for k=1:36
 n=3+mod(k-1,31);rng(140100000+k,'twister');
 a=single(rand(n,1)-0.5);d=double(a);b=single(rand(n,3)-0.5);
 switch mod(k-1,6)
  case 1;a(:)=0;a(1)=single(-0);d=double(a);
  case 2;a(:)=1;a(2:end)=a(2:end)+single((1:n-1)'*2^-22);d=double(a);
  case 3;a=a*single(2^-80);d=double(a);
  case 4;a=a*single(2^70);d=double(a);
  case 5;a(1)=single(NaN);d=double(a);
 end
 S.context=sprintf('D edge case %d',k);
 S=dump(S,'a_single',a);S=dump(S,'B_single',b);
 S=op(S,'sum_a_single',@() sum(a));S=op(S,'norm_a_single',@() norm(a));
 S=op(S,'double_Qt_single_y',@() qtrans(double(b))*a);
 S=op(S,'single_Qt_single_y',@() qtrans(b)*a);
 S=op(S,'corr_double_single',@() corr(b,a));
 S=op(S,'regress_double_X_single_y',@() regress(a,double(b)));
 S=op(S,'regress_single_X_single_y',@() regress(a,b));
end
end
fclose('all');
prov=struct('classification','V1400_SOURCE_DISCLOSED_SINGLE_KERNELS_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'));
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function S=op(S,name,fn)
S.serial=S.serial+1;serial=S.serial;ctx=S.context;
try
 v=fn();S=dump(S,name,v);
 fprintf(S.fs,'%d\t%s\t%s\treturned\t-\t-\n',serial,clean(ctx),clean(name));
catch ME
 fprintf(S.fs,'%d\t%s\t%s\terror\t%s\t%s\n',serial,clean(ctx),clean(name),clean(ME.identifier),clean(ME.message));
end
end

function S=dump(S,name,v)
S.serial=S.serial+1;
if isa(v,'single')
 words=typecast(v(:),'uint32');fwrite(S.fo,words,'uint32');unit=4;
else
 words=typecast(double(v(:)),'uint64');fwrite(S.fo,words,'uint64');unit=8;
end
fprintf(S.ff,'%d,%s,%s,%d,%d,%s,%d\n',S.serial,clean(S.context),clean(name),size(v,1),size(v,2),class(v),unit);
end

function [x,y]=cohort125()
rng(139200125,'twister');N=12;n=40;nsig=8;ne=N*(N-1)/2;
E=rand(ne,n)-0.5;U=rand(n,1)-0.5;
s=E(1,:).';
for k=2:nsig
 w=1/k;if mod(k,2)==0;w=-w;end
 t=w*E(k,:).';s=s+t;
end
t=0.2*U;y=s+t;
x=zeros(N,N,n);L=tril(true(N),-1);
for i=1:n
 M=zeros(N);M(L)=E(:,i);M=M+M.';x(:,:,i)=M;
end
end

function [x,y,cv,partial]=caseerror(c)
partial=c~=124;seed=str2double(sprintf('139200%d',c));
rng(seed,'twister');N=12;n=40;nsig=8;ne=N*(N-1)/2;
E=rand(ne,n)-0.5;U=rand(n,1)-0.5;C=rand(n,1)-0.5;
s=E(1,:).';
for k=2:nsig
 w=1/k;if mod(k,2)==0;w=-w;end
 t=w*E(k,:).';s=s+t;
end
t=0.2*U;y=s+t;cv=C;
if c==37;cv=single(cv);end
if c~=37;y=single(y);end
x=zeros(N,N,n);L=tril(true(N),-1);
for i=1:n
 M=zeros(N);M(L)=E(:,i);M=M+M.';x(:,:,i)=M;
end
if c~=37;x=single(x);end
end

function q=qtrans(a)
[q,~]=qr(a,0);
end

function s=clean(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n,]',' ');if isempty(s);s='-';end
end
