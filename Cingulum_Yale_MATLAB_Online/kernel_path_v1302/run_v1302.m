function run_v1302()
% V1302 original-only X\B envelope probe (source-DISCLOSED diagnostic).
% V1300/V1301 identified hidden X\B as MKL dgeqp3 -> dormqr -> dtrtrs and gave the kernel
% trees. This run fills the gaps before any firstblind claim: dgemm values for every
% right-hand-side width 1..40, a wide dense end-to-end grid, sizes beyond the probed
% envelope, rank-deficient designs (warnings and outputs), signed zeros, structured
% zero-tau designs and larger dtrsm. Inputs are seeded rand('twister')-0.5 so they can
% be regenerated exactly; sections C..F also dump their inputs.
% Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1302_ORIGINAL_ONLY_MLDIVIDE_ENVELOPE_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'));
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1302.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
assert(kp1302('dot',[1 2 3],[4 5 6],0,0)==32);
fprintf(logf,'mex ok\n');
failed=false;
warning('off','backtrace');

% sample of the generator, to confirm exact regeneration outside MATLAB
rng(130299,'twister');
f=fopen(fullfile(outdir,'rand_sample.bin'),'w');fwrite(f,rand(1,64)-0.5,'double');fclose(f);

% ---------------- A. dgemm values as called by dlarfb, every width 1..40 ----------------
try
rng(130201,'twister');
LsTN=[1 2 3 4 7 11 12 13 23 24 25 36 37 48 49 61 72 73 96 97 121 122];
LsNT=[1 2 7 11 12 13 24 25 36 37 49 73 97 122];
WsNT=[1:26 31 32 33 39 40];
fa=fopen(fullfile(outdir,'gemm_out.bin'),'w');assert(fa>0);
arec=zeros(numel(LsTN)*40*8,6);na=0;
for L=LsTN
 for w=1:40
  for k=1:8
   C2=rand(L,w)-0.5;V2=rand(L,k)-0.5;W0=rand(w,k)-0.5;
   W1=kp1302('gemm',1,0,1,C2,V2,1,W0);
   fwrite(fa,W1(:),'double');
   doNT=any(L==LsNT)&&any(w==WsNT);
   if doNT
    O=kp1302('gemm',0,1,-1,V2,W0,1,C2);
    fwrite(fa,O(:),'double');
   end
   na=na+1;arec(na,:)=[L w k double(doNT) chk(C2)+chk(V2)+chk(W0) 0];
  end
 end
end
fclose(fa);
writematrix(arec(1:na,:),fullfile(outdir,'gemm_index.csv'));
fprintf(logf,'A gemm done: %d calls\n',na);
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. dense end to end inside the envelope ----------------
try
rng(130202,'twister');
ms=[12 21 33 47 48 49 56 64 80 96 113 128 130];
ps=[1 2 3 4 6 7 8 9 10 13 15 16 17 20 24 25 31 32];
ws=[1 2 3 4 5 6 7 8 9 10 11 14 16 17 19 20 22 31 40];
fb=fopen(fullfile(outdir,'dense_out.bin'),'w');assert(fb>0);
brec=zeros(numel(ms)*numel(ps)*numel(ws),10);nb=0;idx=0;
for m=ms
 for p=ps
  if p>=m;continue;end
  for w=ws
   idx=idx+1;kind=mod(idx,5);z=0;
   if kind==4
    z=1+mod(idx,7);
    if m-z<=p;z=0;kind=0;end
   end
   mr=m-z;
   X=rand(mr,p)-0.5;B=rand(mr,w)-0.5;
   if kind==1
    X(:,1)=1;
   elseif kind==2
    X=X.*pow2(mod(7*(0:p-1)+idx,13)-6);
   elseif kind==3
    for j=2:2:p;X(:,j)=X(:,j-1)+pow2(-10)*X(:,j);end
   elseif kind==4
    X=[X;zeros(z,p)];B=[B;zeros(z,w)]; %#ok<AGROW>
   end
   lastwarn('');
   H=X\B;
   wm=lastwarn;
   S=kp1302('solve',1,X,B,0);
   fwrite(fb,H(:),'double');
   nb=nb+1;brec(nb,:)=[m p w kind z p*w sum(bits(H)==bits(S)) double(~isempty(wm)) chk(X)+chk(B) 0];
  end
 end
end
fclose(fb);
writematrix(brec(1:nb,:),fullfile(outdir,'dense_index.csv'));
fprintf(logf,'B dense: %d problems, hidden == dgeqp3+dormqr+dtrtrs on %d/%d words, %d warnings\n',nb,sum(brec(1:nb,7)),sum(brec(1:nb,6)),sum(brec(1:nb,8)));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B2. beyond the envelope: larger m and p ----------------
try
rng(130203,'twister');
ms=[131 150 200 257 400 1000];
ps=[8 9 16 32 33 40 48 49 64 65 100 129];
ws=[1 2 12 13];
fb=fopen(fullfile(outdir,'large_out.bin'),'w');assert(fb>0);
brec=zeros(numel(ms)*numel(ps)*numel(ws),9);nb=0;
for m=ms
 for p=ps
  if p>=m;continue;end
  for w=ws
   X=rand(m,p)-0.5;B=rand(m,w)-0.5;
   lastwarn('');
   H=X\B;
   wm=lastwarn;
   S=kp1302('solve',1,X,B,0);
   fwrite(fb,H(:),'double');
   dF=(w==1)&&(m<=400);dQ=(w==1||w==13)&&(m<=400);
   if dF||dQ
    F=kp1302('factor',1,X,0);
    if dF;fwrite(fb,F(:),'double');end
    if dQ
     Q=kp1302('applyq',1,F(1:m,:),F(m+1,:),B,0);
     fwrite(fb,Q(:),'double');
    end
   end
   nb=nb+1;brec(nb,:)=[m p w p*w sum(bits(H)==bits(S)) double(dF) double(dQ) double(~isempty(wm)) chk(X)+chk(B)];
  end
 end
end
fclose(fb);
writematrix(brec(1:nb,:),fullfile(outdir,'large_index.csv'));
fprintf(logf,'B2 large: %d problems, hidden == dgeqp3+dormqr+dtrtrs on %d/%d words\n',nb,sum(brec(1:nb,5)),sum(brec(1:nb,4)));
NV=19;vrec=zeros(0,4+NV);
for m=[131 200 400 1000]
 for k=[9 16 33 64 100]
  for w=[1 12]
   A=rand(m,k)-0.5;
   F=kp1302('factor',1,A,0);V=F(1:m,:);tau=F(m+1,:);
   C=rand(m,w)-0.5;
   O=kp1302('ormqr_variants',V,tau,C);
   e=zeros(1,NV);ref=bits(O(:,:,1));
   for q=1:NV;e(q)=sum(bits(O(:,:,q))==ref);end
   vrec(end+1,:)=[m k w m*w e]; %#ok<AGROW>
  end
 end
end
writematrix(vrec,fullfile(outdir,'large_ormqr_variants.csv'));
fprintf(logf,'B2 ormqr variants done\n');
catch err
 failed=true;fprintf(logf,'SECTION B2 FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

D=struct('fid',fopen(fullfile(outdir,'dump.bin'),'w'),'index',{{}},'pos',0);assert(D.fid>0);

% ---------------- C. rank-deficient and nearly rank-deficient designs ----------------
try
rng(130204,'twister');
es=[20 30 36 40 44 46 48 49 50 51 52 53 54 56];
crec={};
for m=[20 48 65]
 for p=[3 9 12]
  for w=[1 2 13]
   for kind=1:(3+numel(es))
    X=rand(m,p)-0.5;B=rand(m,w)-0.5;
    if kind==1
     X(:,p)=X(:,1);
    elseif kind==2
     X(:,2)=0;
    elseif kind==3
     X(:,p)=X(:,1)+X(:,2);
    else
     X(:,p)=X(:,1)+pow2(-es(kind-3))*X(:,p);
    end
    lastwarn('');
    H=X\B;
    [wm,wid]=lastwarn;
    [S,info]=kp1302('solve',1,X,B,0);
    F=kp1302('factor',1,X,0);
    tag=sprintf('%d_%d_%d_%d',m,p,w,kind);
    D=put(D,['rk_X_' tag],X);D=put(D,['rk_B_' tag],B);D=put(D,['rk_H_' tag],H);
    D=put(D,['rk_S_' tag],S);D=put(D,['rk_F_' tag],F);
    crec{end+1}=struct('m',m,'p',p,'w',w,'kind',kind,'warn_id',wid,'warn_msg',wm,'solve_info',info, ...
     'eq_solve',sum(bits(H)==bits(S)),'words',p*w); %#ok<AGROW>
   end
  end
 end
end
writeJson(fullfile(outdir,'rank_cases.json'),struct('exponents',es,'cases',{crec}));
fprintf(logf,'C rank: %d cases\n',numel(crec));
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- D. signed zeros ----------------
try
rng(130205,'twister');
shapes=[20 3 1;20 3 2;20 3 13;48 9 1;48 9 12;48 9 13;65 12 25;30 5 4];
nz=0;
for si=1:size(shapes,1)
 m=shapes(si,1);p=shapes(si,2);w=shapes(si,3);
 for kind=1:7
  X=rand(m,p)-0.5;B=rand(m,w)-0.5;
  if kind==1
   B(:,1)=0;
  elseif kind==2
   B(:,w)=-0;
  elseif kind==3
   B=-zeros(m,w);
  elseif kind==4
   X(1:3,1)=-0;X(5,:)=0;
  elseif kind==5
   B=repmat(X(:,1),1,w);
  elseif kind==6
   X(1:3,:)=0;B(1:3,:)=0;
  else
   X(:,1)=1;B(:,1)=0;B(:,w)=-0;
  end
  lastwarn('');
  H=X\B;
  S=kp1302('solve',1,X,B,0);
  tag=sprintf('%d_%d_%d_%d',m,p,w,kind);
  D=put(D,['sz_X_' tag],X);D=put(D,['sz_B_' tag],B);D=put(D,['sz_H_' tag],H);D=put(D,['sz_S_' tag],S);
  nz=nz+1;
 end
end
fprintf(logf,'D signed zeros: %d cases\n',nz);
catch err
 failed=true;fprintf(logf,'SECTION D FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- E. structured designs with zero tau and short reflectors ----------------
try
rng(130206,'twister');
shapes=[48 9;48 12;65 10;72 16;100 24;30 6];
ns=0;
for si=1:size(shapes,1)
 m=shapes(si,1);p=shapes(si,2);
 for w=[1 2 13]
  for kind=1:4
   X=rand(m,p)-0.5;B=rand(m,w)-0.5;
   if kind==1
    X=[triu(X(1:p,:))+2*eye(p);zeros(m-p,p)];
   elseif kind==2
    for j=3:p;X(:,j)=0;X(j,j)=0.25;end
   elseif kind==3
    for j=1:p;X(j+3:end,j)=0;end
   else
    for j=2:p;X(j+1:end,j)=0;end
    X(m-4:m,:)=0;B(m-4:m,:)=0;
   end
   lastwarn('');
   H=X\B;
   wm=lastwarn;
   S=kp1302('solve',1,X,B,0);
   tag=sprintf('%d_%d_%d_%d',m,p,w,kind);
   D=put(D,['st_X_' tag],X);D=put(D,['st_B_' tag],B);D=put(D,['st_H_' tag],H);D=put(D,['st_S_' tag],S);
   D=put(D,['st_warn_' tag],double(~isempty(wm)));
   ns=ns+1;
  end
 end
end
fprintf(logf,'E structured: %d cases\n',ns);
catch err
 failed=true;fprintf(logf,'SECTION E FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- F. dtrsm beyond p = 24 ----------------
try
rng(130207,'twister');
nt=0;
for p=[25:31 33:48 64]
 for w=[1 2 3 12 13]
  R=triu(rand(p)-0.5)+diag(2+rand(p,1));B=rand(p,w)-0.5;
  tag=sprintf('%d_%d',p,w);
  D=put(D,['tx_R_' tag],R);D=put(D,['tx_B_' tag],B);
  D=put(D,['tx_out_' tag],kp1302('trsm',R,B));
  nt=nt+1;
 end
end
fprintf(logf,'F trsm: %d cases\n',nt);
catch err
 failed=true;fprintf(logf,'SECTION F FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

fclose(D.fid);
writeJson(fullfile(outdir,'dump_index.json'),struct('records',{D.index}));
fprintf(logf,'dump done, %d doubles\n',D.pos);
assert(~failed,'a V1302 probe section failed; see out/log.txt');
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

function D=put(D,name,A)
A=double(A);
fwrite(D.fid,A(:),'double');
D.index{end+1}=struct('name',name,'dims',size(A),'pos',D.pos);
D.pos=D.pos+numel(A);
end
