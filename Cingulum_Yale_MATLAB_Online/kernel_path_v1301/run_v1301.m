function run_v1301()
% V1301 original-only dormqr/dtrsm/dgeqp3 structure probe (source-DISCLOSED diagnostic).
% V1300 showed hidden X\B == MKL dgeqp3 -> dormqr -> dtrtrs bit for bit. This run asks
% how dormqr, dtrsm and pivoted dgeqp3 are built: which public BLAS/LAPACK sequence
% reproduces them, and what summation trees the kernels under them use.
% Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1301_ORIGINAL_ONLY_DORMQR_STRUCTURE_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'));
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1301.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
assert(kp1301('dot',[1 2 3],[4 5 6],0,0)==32);
fprintf(logf,'mex ok\n');
failed=false;
rng(1301,'twister');
D=struct('fid',fopen(fullfile(outdir,'dump.bin'),'w'),'index',{{}},'pos',0);assert(D.fid>0);

% ---------------- A. which public sequence equals dormqr? (random dense) ----------------
try
NV=19;
vrec=zeros(0,5+NV);
trec=zeros(0,6);
for m=[13 20 30 47 48 51 64 65 67 72 100 130]
 for k=[1 2 3 4 5 8 9 11 12 13 16 20 33]
  if k>m-1;continue;end
  for w=[1 2 3 11 12 13 24 25 37]
   A=randn(m,k);
   F=kp1301('factor',1,A,0);V=F(1:m,:);tau=F(m+1,:);
   C=randn(m,w);
   O=kp1301('ormqr_variants',V,tau,C);
   e=zeros(1,NV);
   ref=bits(O(:,:,1));
   for q=1:NV;e(q)=sum(bits(O(:,:,q))==ref);end
   vrec(end+1,:)=[m k w m*w 0 e]; %#ok<AGROW>
   if w==1
    Tv=kp1301('larft_variants',V,tau);
    mk=triu(true(k));
    T1=Tv(:,:,1);T2=Tv(:,:,2);T3=Tv(:,:,3);
    trec(end+1,:)=[m k nnz(mk) sum(bits(T2(mk))==bits(T1(mk))) sum(bits(T3(mk))==bits(T1(mk))) 0]; %#ok<AGROW>
    if any(m==[30 48 65 72]) && any(k==[2 3 4 5 8 9 11 12])
     tag=sprintf('%d_%d',m,k);
     D=put(D,['lt_V_' tag],V);D=put(D,['lt_tau_' tag],tau);D=put(D,['lt_T_' tag],Tv);
    end
   end
   if any(m==[48 65]) && any(k==[2 9 12]) && any(w==[1 12 13 25])
    tag=sprintf('%d_%d_%d',m,k,w);
    D=put(D,['ov_V_' tag],V);D=put(D,['ov_tau_' tag],tau);D=put(D,['ov_C_' tag],C);
    D=put(D,['ov_out_' tag],O(:,:,[1 2 3 6]));
   end
  end
 end
end
writematrix(vrec,fullfile(outdir,'ormqr_variants.csv'));
writematrix(trec,fullfile(outdir,'larft_variants.csv'));
tot=sum(vrec(:,4));
for q=1:NV
 fprintf(logf,'ormqr variant %2d equals dormqr on %d/%d words; shapes fully equal %d/%d\n',q-1,sum(vrec(:,5+q)),tot,sum(vrec(:,5+q)==vrec(:,4)),size(vrec,1));
end
fprintf(logf,'larft nonrec==MKL dlarft: %d/%d ; recursive==MKL dlarft: %d/%d\n',sum(trec(:,4)),sum(trec(:,3)),sum(trec(:,5)),sum(trec(:,3)));
% T as dormqr itself uses it, read through an identity block planted in V
tr=zeros(0,6);
for m=[30 48 65 72]
 for k=2:12
  for trial=1:3
   V=randn(m,k);V(1:k,:)=tril(V(1:k,:),-1)+eye(k);V(k+1:2*k,:)=eye(k);
   tau=1+0.5*rand(1,k);
   Tq=kp1301('ormqr_T',V,tau);
   Tv=kp1301('larft_variants',V,tau);
   mk=triu(true(k),1);
   c=zeros(1,3);
   for q=1:3;Tx=Tv(:,:,q);c(q)=sum(bits(Tq(mk))==bits(Tx(mk)));end
   tr(end+1,:)=[m k nnz(mk) c]; %#ok<AGROW>
   tag=sprintf('%d_%d_%d',m,k,trial);
   D=put(D,['tq_V_' tag],V);D=put(D,['tq_tau_' tag],tau);D=put(D,['tq_T_' tag],Tq);D=put(D,['tq_Tv_' tag],Tv);
  end
 end
end
writematrix(tr,fullfile(outdir,'ormqr_T_readout.csv'));
fprintf(logf,'T used by dormqr vs MKL dlarft %d/%d, nonrec %d/%d, recursive %d/%d\n',sum(tr(:,4)),sum(tr(:,3)),sum(tr(:,5)),sum(tr(:,3)),sum(tr(:,6)),sum(tr(:,3)));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- B. summation trees of the public kernels under dlarfb/dtrsm ----------------
try
ws=[1 2 3 4 5 6 7 8 9 11 12 13 14 23 24 25 26 36 37];
ks=[1 2 3 4 5 6 7 8 9 10 11 12 13 16];
for L=1:72
 for w=ws
  for k=ks
   kp1301('fprev_gemmTN',w,k,L);
  end
 end
end
fprintf(logf,'fprev gemmTN done\n');
for L=[1:20 36:40 47 48 52:57 63:66 71 72]
 for w=ws
  for k=ks
   kp1301('fprev_gemmNT',L,w,k);
  end
 end
end
fprintf(logf,'fprev gemmNT done\n');
for var=1:3
 for w=[1:14 23:26 36 37]
  for k=1:20
   kp1301('fprev_trmm',var,w,k);
  end
 end
end
for n=1:40;kp1301('fprev_trmv',n);end
for p=2:24
 for w=[1:14 23:26 36 37 48 49]
  kp1301('fprev_trsm',p,w);
 end
end
for p=[32 33 40 48 64 65]
 for w=[1 2 12 13 25]
  kp1301('fprev_trsm',p,w);
 end
end
fprintf(logf,'fprev trmm/trmv/trsm done\n');
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- C. composite: tree of W(c,i)=C(:,c)''v_i inside dormqr ----------------
try
for m=[16 20 47 48 49 50 51 64 65 66 67]
 for k=[1 2 3 4 5 8 9 10 11 12]
  for w=[1 2 3 4 11 12 13 24 25]
   for i=0:k-1
    kp1301('fprev_ormqr',m,k,w,i);
   end
  end
 end
 fprintf(logf,'fprev ormqr m=%d done\n',m);
end
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
cnt=kp1301('reg_save',fullfile(outdir,'fprev_unique.bin'),fullfile(outdir,'fprev_index.bin'));
fprintf(logf,'registry: %d unique trees, %d index words\n',cnt(1),cnt(2));

% ---------------- D. raw dumps: gemm/trmm/trsm values, pivoted dgeqp3, end to end ----------------
try
for L=[1 2 3 5 8 9 16 17 36 37 47 53 56 64 65]
 for w=[1 2 11 12 13 25]
  for k=[1 2 3 4 9 12]
   C2=randn(L,w);V2=randn(L,k);W0=randn(w,k);
   tag=sprintf('%d_%d_%d',L,w,k);
   D=put(D,['gm_C2_' tag],C2);D=put(D,['gm_V2_' tag],V2);D=put(D,['gm_W0_' tag],W0);
   W1=kp1301('gemm',1,0,1,C2,V2,1,W0);
   D=put(D,['gm_TN_' tag],W1);
   D=put(D,['gm_NT_' tag],kp1301('gemm',0,1,-1,V2,W0,1,C2));
  end
 end
end
for w=[1 2 11 12 13 25]
 for k=[2 3 4 5 8 9 11 12 16]
  W0=randn(w,k);Tm=randn(k);
  tag=sprintf('%d_%d',w,k);
  D=put(D,['tm_W_' tag],W0);D=put(D,['tm_T_' tag],Tm);
  D=put(D,['tm_1_' tag],kp1301('trmm',1,W0,Tm));
  D=put(D,['tm_2_' tag],kp1301('trmm',2,W0,Tm));
  D=put(D,['tm_3_' tag],kp1301('trmm',3,W0,Tm));
  x=randn(k,1);
  D=put(D,['tv_x_' tag],x);D=put(D,['tv_out_' tag],kp1301('trmv',Tm,x));
 end
end
for p=[2:16 20 24 32 33 40]
 for w=[1 2 3 11 12 13 25 37]
  R=triu(randn(p))+diag((2+rand(p,1)).*sign(randn(p,1)));B=randn(p,w);
  tag=sprintf('%d_%d',p,w);
  D=put(D,['tri_R_' tag],R);D=put(D,['tri_B_' tag],B);
  D=put(D,['trsm_out_' tag],kp1301('trsm',R,B));
 end
end
% pivoted dgeqp3 on dense and graded matrices
shapes=[10 3;20 5;48 9;48 12;65 11;65 12;72 20;100 33;100 40;130 48;30 30;12 20];
for si=1:size(shapes,1)
 m=shapes(si,1);n=shapes(si,2);
 for trial=1:4
  A=randn(m,n);
  if trial==3;A=A.*pow2(randi([-6 6],1,n));end
  if trial==4;A(:,2:2:end)=A(:,1:2:2*floor(n/2))+1e-3*randn(m,floor(n/2));end
  tag=sprintf('%d_%d_%d',m,n,trial);
  D=put(D,['qp_A_' tag],A);
  D=put(D,['qp_F_' tag],kp1301('factor',1,A,0));
  [~,R,P]=qr(A,'econ','vector');
  D=put(D,['qp_R_' tag],R);D=put(D,['qp_P_' tag],P);
 end
end
% end to end on dense synthetic problems
erec=zeros(0,6);
for m=[20 48 65 72 100]
 for p=[1 2 3 5 9 12]
  for w=[1 2 12 13 25 40]
   X=randn(m,p);B=randn(m,w);
   tag=sprintf('%d_%d_%d',m,p,w);
   H=X\B;
   S=kp1301('solve',1,X,B,0);
   erec(end+1,:)=[m p w p*w sum(bits(H)==bits(S)) 0]; %#ok<AGROW>
   F=kp1301('factor',1,X,0);
   D=put(D,['ee_X_' tag],X);D=put(D,['ee_B_' tag],B);D=put(D,['ee_hidden_' tag],H);
   D=put(D,['ee_F_' tag],F);
   D=put(D,['ee_QtB_' tag],kp1301('applyq',1,F(1:m,:),F(m+1,:),B,0));
  end
 end
end
fprintf(logf,'dense end to end: hidden X\\B == dgeqp3+dormqr+dtrtrs on %d/%d words\n',sum(erec(:,5)),sum(erec(:,4)));
writematrix(erec,fullfile(outdir,'dense_end_to_end.csv'));
catch err
 failed=true;fprintf(logf,'SECTION D FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fclose(D.fid);
writeJson(fullfile(outdir,'dump_index.json'),struct('records',{D.index}));
fprintf(logf,'dump done, %d doubles\n',D.pos);
assert(~failed,'a V1301 probe section failed; see out/log.txt');
end

function u=bits(a)
u=typecast(double(a(:)),'uint64');
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
