function run_v1321()
% V1321 original-only triangular-solve and small-product probe (source-DISCLOSED diagnostic).
% V1320 showed that a public-API twin equals unchanged robustfit on every field, and that
% X/R (leverage) is not a plain dtrsm('R','U','N','N') call and A'*x differs from dgemv on
% very small shapes. This run identifies what X/R and R\B call for every shape in scope,
% reads their summation trees through MATLAB's own operators, and maps the small-shape
% A'*x behaviour (including alignment sensitivity of the gateway call).
% Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1321_ORIGINAL_ONLY_TRIANGULAR_SOLVE_AND_SMALL_PRODUCT_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'));
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1321.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
assert(kp1321('dot',[1 2 3],[4 5 6],0,0)==32);
fprintf(logf,'mex ok\n');
failed=false;
warning('off','backtrace');
tStart=tic;
M=pow2(62);
pl=[1:17 20 24 25 31 32];

% ---------------- A. X/R against every candidate, all shapes in scope ----------------
try
rng(132101,'twister');
NC=8;
arec=zeros(130*32,3+NC);na=0;
fa=fopen(fullfile(outdir,'mrdivide_out.bin'),'w');assert(fa>0);
for n=1:130
 for p=1:32
  X=rand(n,p)-0.5;R=triu(rand(p)-0.5)+diag(1+rand(p,1));
  if mod(n+p,3)==0;R=R-diag(2*diag(R).*(rand(p,1)<0.5));end
  Em=X/R;
  Xt=X.';
  c=cell(1,NC);
  c{1}=kp1321('trsmR',R,X,0);
  c{2}=kp1321('trsmG',0,R,Xt).';
  c{3}=kp1321('trsmG',1,R.',Xt).';
  c{4}=kp1321('trsvT',R,Xt).';
  c{5}=kp1321('trtrsT',R,Xt).';
  c{6}=kp1321('rsolve_ref',R,X,0);
  c{7}=kp1321('rsolve_ref',R,X,1);
  c{8}=(R.'\Xt).';
  e=zeros(1,NC);
  for q=1:NC;e(q)=sum(bits(Em)==bits(c{q}));end
  na=na+1;arec(na,:)=[n p n*p e];
  if any(p==pl)
   fwrite(fa,X(:),'double');fwrite(fa,R(:),'double');fwrite(fa,Em(:),'double');
  end
 end
end
fclose(fa);
writematrix(arec(1:na,:),fullfile(outdir,'mrdivide_index.csv'));
names={'dtrsm R,U,N,N','dtrsm L,U,T,N on X.''','dtrsm L,L,N,N on R.'',X.''','dtrsv U,T per row','dtrtrs U,T','plain loops, division','plain loops, reciprocal','MATLAB (R.''\X.'').'''};
for q=1:NC;fprintf(logf,'A X/R == %s: %d/%d words, %d/%d shapes\n',names{q},sum(arec(1:na,3+q)),sum(arec(1:na,3)),sum(arec(1:na,3+q)==arec(1:na,3)),na);end
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- B. R\B against the candidates ----------------
try
rng(132102,'twister');
wl=[1:40 47:50 63:66 96 97 127:130];
brec=zeros(32*numel(wl),7);nb=0;
fb=fopen(fullfile(outdir,'mldivide_tri_out.bin'),'w');assert(fb>0);
for p=1:32
 for w=wl
  R=triu(rand(p)-0.5)+diag(1+rand(p,1));B=rand(p,w)-0.5;
  if mod(p+w,3)==0;R=R-diag(2*diag(R).*(rand(p,1)<0.5));end
  Bm=R\B;
  e=[sum(bits(Bm)==bits(kp1321('trsm',R,B))) sum(bits(Bm)==bits(kp1321('trsv',R,B))) ...
     sum(bits(Bm)==bits(kp1321('lsolve_ref',R,B,0))) sum(bits(Bm)==bits(kp1321('lsolve_ref',R,B,1)))];
  nb=nb+1;brec(nb,:)=[p w p*w e];
  if w==p||w<=3
   Be=R\eye(p);
   fwrite(fb,R(:),'double');fwrite(fb,B(:),'double');fwrite(fb,Bm(:),'double');fwrite(fb,Be(:),'double');
  end
 end
end
fclose(fb);
writematrix(brec(1:nb,:),fullfile(outdir,'mldivide_tri_index.csv'));
fprintf(logf,'B R\\B == dtrsm %d, dtrsv per column %d, plain division %d, plain reciprocal %d of %d words\n',sum(brec(1:nb,4)),sum(brec(1:nb,5)),sum(brec(1:nb,6)),sum(brec(1:nb,7)),sum(brec(1:nb,3)));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- D. alignment sensitivity and identity of small A'*x ----------------
try
rng(132104,'twister');
offs=[0 1 2 4 6];
ml=[1:24 31:34 47:50 63:66];
drec=zeros(numel(ml)*6,3+25+6);nd=0;
for m=ml
 for p=1:6
  A=rand(m,p)-0.5;x=rand(m,1)-0.5;
  ref=A'*x;
  e=zeros(1,25);k=0;g0=[];alls=1;
  for oa=offs
   for ox=offs
    k=k+1;g=kp1321('gemv',1,A,x,oa,ox,0);
    e(k)=sum(bits(g)==bits(ref));
    if k==1;g0=g;else;alls=alls&&isequal(bits(g),bits(g0));end
   end
  end
  egm=sum(bits(kp1321('gemm',1,0,1,A,x,0,zeros(p,1)))==bits(ref));
  ed=[-1 -1 -1 -1];
  if p==1
   ed=[double(bits(kp1321('dot',A,x,0,0))==bits(ref)) double(bits(kp1321('dot',A,x,1,0))==bits(ref)) ...
       double(bits(kp1321('dot',A,x,2,4))==bits(ref)) double(bits(dot(A,x))==bits(ref))];
  end
  nd=nd+1;drec(nd,:)=[m p p e double(alls) egm ed];
 end
end
writematrix(drec(1:nd,:),fullfile(outdir,'small_product_index.csv'));
d=drec(1:nd,:);
fprintf(logf,'D small A''*x: %d shapes; gateway dgemvT at offsets (0,0) equal on %d/%d words; offset-independent in %d/%d shapes; dgemm T,N equal on %d/%d\n',nd,sum(d(:,4)),sum(d(:,3)),sum(d(:,29)),nd,sum(d(:,30)),sum(d(:,3)));
d1=d(d(:,2)==1,:);
fprintf(logf,'D p=1: ddot (0,0) %d, (1,0) %d, (2,4) %d, MATLAB dot() %d of %d\n',sum(d1(:,31)),sum(d1(:,32)),sum(d1(:,33)),sum(d1(:,34)),size(d1,1));
catch err
 failed=true;fprintf(logf,'SECTION D FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- E. values of A'*x and A*x ----------------
try
rng(132105,'twister');
ml=[1:64 65 80 96 97 127:130];
fe=fopen(fullfile(outdir,'product_out.bin'),'w');assert(fe>0);
erec=zeros(numel(ml)*33,8);ne=0;
for m=ml
 for p=1:33
  A=rand(m,p)-0.5;x=rand(m,1)-0.5;xb=rand(p,1)-0.5;
  yT=A'*x;yN=A*xb;
  fwrite(fe,A(:),'double');fwrite(fe,x(:),'double');fwrite(fe,xb(:),'double');fwrite(fe,yT(:),'double');fwrite(fe,yN(:),'double');
  ed=-1;if p==1;ed=double(bits(kp1321('dot',A,x,0,0))==bits(yT));end
  ne=ne+1;
  erec(ne,:)=[m p sum(bits(yT)==bits(kp1321('gemv',1,A,x,0,0,0))) sum(bits(yT)==bits(kp1321('gemm',1,0,1,A,x,0,zeros(p,1)))) ed ...
   sum(bits(yN)==bits(kp1321('gemv',0,A,xb,0,0,0))) sum(bits(yN)==bits(kp1321('gemm',0,0,1,A,xb,0,zeros(m,1)))) chk(A)];
 end
end
fclose(fe);
writematrix(erec(1:ne,:),fullfile(outdir,'product_index.csv'));
fprintf(logf,'E products: %d shapes; A''*x == dgemvT %d, dgemm %d of %d; A*x == dgemvN %d, dgemm %d of %d\n',ne,sum(erec(1:ne,3)),sum(erec(1:ne,4)),sum(erec(1:ne,2)),sum(erec(1:ne,6)),sum(erec(1:ne,7)),sum(erec(1:ne,1)));
catch err
 failed=true;fprintf(logf,'SECTION E FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- C. summation trees read through MATLAB's own operators ----------------
try
% C1: R\B, w = p and w = 1 (kinds 33 and 34)
for p=2:32
 for wsel=1:2
  w=p;if wsel==2;w=1;end
  for i=1:p-1
   nl=p-i+1;
   R=eye(p);R(i,i+1:p)=1;
   T=zeros(nl,nl,w);
   for a=1:nl-1
    for b=a+1:nl
     Bv=[zeros(i-1,1);-1;ones(p-i,1)];
     if a==1;Bv(i)=M;else;Bv(i+a-1)=-M;end
     Bv(i+b-1)=M;
     Bm=R\repmat(Bv,1,w);
     T(a,b,:)=-Bm(i,:);T(b,a,:)=-Bm(i,:);
    end
   end
   kp1321('reg_tab',32+wsel,p,w,i,0,T);
  end
 end
end
fprintf(logf,'C1 R\\B trees done t=%.1f\n',toc(tStart));
% C2: X/R (kind 32)
for n=1:130
 for p=pl
  if p<2;continue;end
  for jj=2:p
   R=eye(p);R(1:jj-1,jj)=-1;
   X=ones(n,p);T=zeros(jj,jj,n);
   for a=1:jj-1
    for b=a+1:jj
     X(:,a)=M;X(:,b)=-M;
     Em=X/R;
     X(:,a)=1;X(:,b)=1;
     T(a,b,:)=Em(:,jj);T(b,a,:)=Em(:,jj);
    end
   end
   kp1321('reg_tab',32,n,p,jj,0,T);
  end
 end
end
fprintf(logf,'C2 X/R trees done t=%.1f\n',toc(tStart));
cnt=kp1321('reg_save',fullfile(outdir,'fprev_unique.bin'),fullfile(outdir,'fprev_index.bin'));
fprintf(logf,'C registry after C2: unique=%d index=%d\n',cnt(1),cnt(2));
% C3: A'*x (kind 30)
pT=[1:12 13 16 17 20 24 25 31 32 33];
for m=2:130
 for p=pT
  A=ones(m,p);x=ones(m,1);T=zeros(m,m,p);
  for a=1:m-1
   for b=a+1:m
    A(a,:)=M;A(b,:)=-M;
    y=A'*x;
    A(a,:)=1;A(b,:)=1;
    T(a,b,:)=y;T(b,a,:)=y;
   end
  end
  kp1321('reg_tab',30,m,p,0,0,T);
 end
end
fprintf(logf,'C3 A''*x trees done t=%.1f\n',toc(tStart));
cnt=kp1321('reg_save',fullfile(outdir,'fprev_unique.bin'),fullfile(outdir,'fprev_index.bin'));
fprintf(logf,'C registry: unique=%d index=%d\n',cnt(1),cnt(2));
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));
assert(~failed,'a V1321 probe section failed; see out/log.txt');
end

function u=bits(a)
u=typecast(double(a(:)),'uint64');
end

function c=chk(a)
c=sum(double(typecast(double(a(:)),'uint32')));
end

function writeJson(path,value)
f=fopen(path,'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(value));
fclose(f);
end
