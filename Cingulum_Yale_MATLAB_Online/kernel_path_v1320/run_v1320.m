function run_v1320()
% V1320 original-only robustfit kernel path probe (source-DISCLOSED diagnostic).
% V1300..V1310 settled hidden X\B (dgeqp3 -> dormqr -> dtrtrs) on the AMD path. This run
% measures the other numerical steps a multi-predictor robustfit takes, each in isolation:
% explicit economy Q, Q'*y, R\z, X/R, row sums of squares, X*b, R\eye, RI*RI', linsolve
% with RECT, vector sum/mean/std/norm, and tcdf. It then runs unchanged robustfit on new
% synthetic cohorts next to a public-API twin written for this probe, and dumps every
% stage of the twin so the first differing stage (if any) can be located.
% Synthetic seeded inputs only. Reads no Rust forecast and no earlier MATLAB output.
global V1320_CB %#ok<GVMIS>
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1320_ORIGINAL_ONLY_ROBUSTFIT_KERNEL_PATH_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'));
[~,t]=system('lscpu');prov.lscpu=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1320.c'),'-lmwblas','-lmwlapack');
addpath(outdir);
assert(kp1320('dot',[1 2 3],[4 5 6],0,0)==32);
fprintf(logf,'mex ok\n');
failed=false;
warning('off','backtrace');
tStart=tic;

rng(132099,'twister');
f=fopen(fullfile(outdir,'rand_sample.bin'),'w');fwrite(f,rand(1,64)-0.5,'double');fclose(f);

D=struct('fid',fopen(fullfile(outdir,'dump.bin'),'w'),'index',{{}},'pos',0);assert(D.fid>0);

% ---------------- A. each robustfit step against the gateway, in isolation ----------------
try
rng(132001,'twister');
ms=[6 12 20 33 47 48 49 64 65 80 97 128 130];
ps=[1:10 12 13 15 16 17 20 24 25 31 32];
NQ=8;
arec=zeros(numel(ms)*numel(ps)*4,45);na=0;
for m=ms
 for p=ps
  if p>=m;continue;end
  for kind=0:3
   X=rand(m,p)-0.5;y=rand(m,1)-0.5;bv=rand(p,1)-0.5;
   if kind==1
    X(:,1)=1;
   elseif kind==2
    z=min(1+mod(m+p,5),m-p-1);
    if z>=1;X(m-z+1:m,:)=0;y(m-z+1:m)=0;end
   elseif kind==3
    X(:,1)=1;sw=rand(m,1);sw(sw<0.15)=0;
    if nnz(sw)<=p+1;sw(:)=1;end
    X=X.*sw;y=y.*sw;
   end
   tag=sprintf('%d_%d_%d',m,p,kind);
   lastwarn('');
   [Q,R,perm]=qr(X,0);
   F=kp1320('factor',1,X,0);pk=F(1:m,:);tau=F(m+1,:);jp=F(m+2,:);
   mu=triu(true(p));Rg=triu(pk(1:p,:));
   eqR=sum(bits(R(mu))==bits(Rg(mu)));eqperm=sum(perm(:)==jp(:));
   eqQ=zeros(1,NQ);
   for q=1:NQ
    Qg=kp1320('orgq',q-1,pk,tau);
    eqQ(q)=sum(bits(Q)==bits(Qg));
   end
   qy=Q'*y;
   eqqy=sum(bits(qy)==bits(kp1320('gemv',1,Q,y,0,0,0)));
   z1=R\qy;
   eqz=[sum(bits(z1)==bits(kp1320('trsv',R,qy))) sum(bits(z1)==bits(kp1320('trsm',R,qy))) sum(bits(z1)==bits(kp1320('trtrs',R,qy)))];
   Xp=X(:,perm);
   E=Xp/R;
   eqE=[sum(bits(E)==bits(kp1320('trsmR',R,Xp,0))) sum(bits(E)==bits(kp1320('trsmR',R,Xp,1)))];
   h=sum(E.*E,2);
   hf=zeros(m,1);for j=1:p;hf=hf+E(:,j).*E(:,j);end
   eqh=sum(bits(h)==bits(hf));
   fx=X*bv;
   eqf=sum(bits(fx)==bits(kp1320('gemv',0,X,bv,0,0,0)));
   r1=y-X*bv;
   eqr=[sum(bits(r1)==bits(y-fx)) sum(bits(r1)==bits(kp1320('gemv2',0,-1,X,bv,1,y)))];
   RI=R\eye(p);
   eqRI=[sum(bits(RI)==bits(kp1320('trsm',R,eye(p)))) sum(bits(RI)==bits(kp1320('trtrs',R,eye(p)))) ...
         sum(bits(RI)==bits(kp1320('trsv',R,eye(p)))) sum(bits(RI(mu))==bits(pick(kp1320('trtri',R),mu)))];
   C=RI*RI';
   ml=tril(true(p));
   eqC=[sum(bits(C(mu))==bits(pick(kp1320('syrk',0,RI),mu))) sum(bits(C(ml))==bits(pick(kp1320('syrk',1,RI),ml))) ...
        sum(bits(C)==bits(kp1320('gemm',0,1,1,RI,RI,0,zeros(p)))) sum(bits(C)==bits(C'))];
   nrm=norm(r1);
   eqn=double(bits(nrm)==bits(kp1320('nrm2',r1,0)));
   wm=lastwarn;
   D=put(D,['a_X_' tag],X);D=put(D,['a_y_' tag],y);D=put(D,['a_bv_' tag],bv);
   D=put(D,['a_F_' tag],F);D=put(D,['a_Q_' tag],Q);D=put(D,['a_R_' tag],R);D=put(D,['a_perm_' tag],perm);
   D=put(D,['a_qy_' tag],qy);D=put(D,['a_z_' tag],z1);D=put(D,['a_E_' tag],E);D=put(D,['a_h_' tag],h);
   D=put(D,['a_fx_' tag],fx);D=put(D,['a_r_' tag],r1);D=put(D,['a_RI_' tag],RI);D=put(D,['a_C_' tag],C);
   D=put(D,['a_nrm_' tag],nrm);
   na=na+1;
   row=[m p kind p*(p+1)/2 eqR eqperm m*p eqQ p eqqy eqz m*p eqE m eqh eqf eqr p*p eqRI eqC eqn double(~isempty(wm))];
   assert(numel(row)==31+NQ);
   arec(na,1:numel(row))=row;
  end
 end
end
writematrix(arec(1:na,:),fullfile(outdir,'steps_index.csv'));
a=arec(1:na,:);
fprintf(logf,'A steps: %d cases\n',na);
fprintf(logf,' R %d/%d perm %d/%d\n',sum(a(:,5)),sum(a(:,4)),sum(a(:,6)),sum(a(:,2)));
names={'dorgqr','dorg2r','dormqrN','dorm2rN','blk4','blk8','blk16','blk32'};
for q=1:NQ;fprintf(logf,' Q == %s: %d/%d\n',names{q},sum(a(:,7+q)),sum(a(:,7)));end
c=7+NQ;
fprintf(logf,' Qty == dgemvT %d/%d\n',sum(a(:,c+2)),sum(a(:,c+1)));
fprintf(logf,' R\\z == trsv %d trsm %d trtrs %d of %d\n',sum(a(:,c+3)),sum(a(:,c+4)),sum(a(:,c+5)),sum(a(:,c+1)));
fprintf(logf,' X/R == dtrsmR off0 %d off1 %d of %d\n',sum(a(:,c+7)),sum(a(:,c+8)),sum(a(:,c+6)));
fprintf(logf,' sum(E.*E,2) == forward %d/%d\n',sum(a(:,c+10)),sum(a(:,c+9)));
fprintf(logf,' X*b == dgemvN %d/%d ; y-X*b == separate %d fused %d\n',sum(a(:,c+11)),sum(a(:,c+9)),sum(a(:,c+12)),sum(a(:,c+13)));
fprintf(logf,' R\\eye == trsm %d trtrs %d trsv %d trtri(upper) %d of %d\n',sum(a(:,c+15)),sum(a(:,c+16)),sum(a(:,c+17)),sum(a(:,c+18)),sum(a(:,c+14)));
fprintf(logf,' RI*RI'' == syrkU(upper) %d syrkL(lower) %d of %d ; gemmNT %d symmetric %d of %d\n',sum(a(:,c+19)),sum(a(:,c+20)),sum(a(:,4)),sum(a(:,c+21)),sum(a(:,c+22)),sum(a(:,c+14)));
fprintf(logf,' norm == dnrm2 %d/%d ; warnings %d\n',sum(a(:,c+23)),na,sum(a(:,c+24)));
catch err
 failed=true;fprintf(logf,'SECTION A FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- B. linsolve with RECT against backslash and the gateway ----------------
try
rng(132002,'twister');
ms=[12 20 33 48 49 64 80 97 130];
ps=[1 2 3 4 5 6 8 9 10 13 16 17 25 32];
opts=struct('RECT',true);
brec=zeros(numel(ms)*numel(ps)*5,12);nb=0;
for m=ms
 for p=ps
  if p+2>=m;continue;end
  for kind=0:4
   X=rand(m,p)-0.5;y=rand(m,1)-0.5;
   if kind>=1;X(:,1)=1;end
   if kind==2||kind==3
    sw=rand(m,1);sw(sw<0.2)=0;
    if kind==3;sw(m-2:m)=0;end
    if nnz(sw)<=p+1;sw(:)=1;end
    X=X.*sw;y=y.*sw;
   elseif kind==4
    if p>=2;X(:,p)=X(:,1);end
   end
   tag=sprintf('%d_%d_%d',m,p,kind);
   lastwarn('');
   [bL,rL]=linsolve(X,y,opts);
   wL=lastwarn;lastwarn('');
   bB=X\y;
   wB=lastwarn;
   [S,info]=kp1320('solve',1,X,y,0);
   D=put(D,['b_X_' tag],X);D=put(D,['b_y_' tag],y);D=put(D,['b_L_' tag],bL);D=put(D,['b_B_' tag],bB);D=put(D,['b_S_' tag],S);
   nb=nb+1;
   brec(nb,:)=[m p kind p sum(bits(bL)==bits(bB)) sum(bits(bL)==bits(S)) rL info double(~isempty(wL)) double(~isempty(wB)) chk(X) 0];
  end
 end
end
writematrix(brec(1:nb,:),fullfile(outdir,'linsolve_index.csv'));
fprintf(logf,'B linsolve: %d cases, == backslash %d/%d, == gateway %d/%d, linsolve warnings %d, backslash warnings %d\n',nb, ...
 sum(brec(1:nb,5)),sum(brec(1:nb,4)),sum(brec(1:nb,6)),sum(brec(1:nb,4)),sum(brec(1:nb,9)),sum(brec(1:nb,10)));
catch err
 failed=true;fprintf(logf,'SECTION B FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- C. vector built-ins: values, twins and summation trees ----------------
try
rng(132003,'twister');
NREP=4;crec=zeros(200*NREP,14);nc=0;
for n=1:200
 for rep=1:NREP
  v=rand(n,1)-0.5;
  if rep==3;v=v.*pow2(mod((1:n)',11)-5);end
  if rep==4;v=abs(v);end
  s=sum(v);mn=mean(v);nm=norm(v);md=median(v);
  if n>=2;sd=std(v);vr=var(v);else;sd=0;vr=0;end
  fs=0;for i=1:n;fs=fs+v(i);end
  d=v-mn;sd2=sqrt(sum(abs(d).^2)/max(n-1,1));sd3=sqrt(sum(d.*d)/max(n-1,1));
  nc=nc+1;
  crec(nc,:)=[n rep double(bits(s)==bits(fs)) double(bits(mn)==bits(s/n)) double(bits(nm)==bits(kp1320('nrm2',v,0))) ...
   double(bits(sd)==bits(sd2)) double(bits(sd)==bits(sd3)) double(bits(sd)==bits(sqrt(vr))) 0 0 0 0 0 0];
  D=put(D,sprintf('c_v_%d_%d',n,rep),[s;mn;nm;md;sd;vr]);
 end
end
writematrix(crec(1:nc,:),fullfile(outdir,'vector_index.csv'));
fprintf(logf,'C vectors: %d cases; sum==forward %d mean==sum/n %d norm==dnrm2 %d std==twinA %d twinB %d std==sqrt(var) %d\n',nc, ...
 sum(crec(1:nc,3)),sum(crec(1:nc,4)),sum(crec(1:nc,5)),sum(crec(1:nc,6)),sum(crec(1:nc,7)),sum(crec(1:nc,8)));
M=pow2(62);
for n=[2:130 160 200]
 x=ones(n,1);T=zeros(n,n);
 for a=1:n-1
  for b=a+1:n
   x(a)=M;x(b)=-M;r=sum(x);x(a)=1;x(b)=1;
   T(a,b)=r;T(b,a)=r;
  end
 end
 D=put(D,sprintf('c_sumtree_%d',n),T);
end
fprintf(logf,'C sum(v) trees done\n');
nsame=0;ntot=0;
for n=[1 2 5 33 130]
 for p=2:40
  A=ones(n,p);T=zeros(p,p);same=true;
  for a=1:p-1
   for b=a+1:p
    A(:,a)=M;A(:,b)=-M;r=sum(A,2);A(:,a)=1;A(:,b)=1;
    T(a,b)=r(1);T(b,a)=r(1);same=same&&all(r==r(1));
   end
  end
  D=put(D,sprintf('c_sum2tree_%d_%d',n,p),T);
  nsame=nsame+double(same);ntot=ntot+1;
 end
end
fprintf(logf,'C sum(A,2) trees done; all rows share one tree in %d/%d shapes\n',nsame,ntot);
catch err
 failed=true;fprintf(logf,'SECTION C FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- D. gateway summation trees ----------------
try
pl=[1:17 20 24 25 31 32];
for n=1:130
 for p=pl
  if p>=2;kp1320('fprev_trsmR',n,p);end
 end
end
fprintf(logf,'D trsmR trees done t=%.1f\n',toc(tStart));
for m=1:130
 for ncol=1:33
  kp1320('fprev_gemvN2',m,ncol,0);
  kp1320('fprev_gemvN2',m,ncol,1);
 end
end
fprintf(logf,'D gemvN trees done t=%.1f\n',toc(tStart));
for p=2:32
 kp1320('fprev_syrk',p,p,0);
 kp1320('fprev_syrk',p,p,1);
 kp1320('fprev_gemmNT0',p,p,p);
end
fprintf(logf,'D syrk/gemm trees done t=%.1f\n',toc(tStart));
cnt=kp1320('reg_save',fullfile(outdir,'fprev_unique.bin'),fullfile(outdir,'fprev_index.bin'));
fprintf(logf,'D registry: unique=%d index=%d\n',cnt(1),cnt(2));
catch err
 failed=true;fprintf(logf,'SECTION D FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- E. values for the FMA / reciprocal decisions ----------------
try
rng(132005,'twister');
nl=[1:40 47:50 63:66 96 97 127:130];
fe=fopen(fullfile(outdir,'trsmR_out.bin'),'w');assert(fe>0);
erec=zeros(numel(nl)*32,6);ne=0;
for n=nl
 for p=1:32
  X=rand(n,p)-0.5;R=triu(rand(p)-0.5)+diag(1+rand(p,1));
  if mod(n+p,3)==0;R=R-diag(2*diag(R).*(rand(p,1)<0.5));end
  G=kp1320('trsmR',R,X,0);
  Em=X/R;
  fwrite(fe,X(:),'double');fwrite(fe,R(:),'double');fwrite(fe,G(:),'double');
  ne=ne+1;erec(ne,:)=[n p n*p sum(bits(Em)==bits(G)) chk(X)+chk(R) 0];
 end
end
fclose(fe);
writematrix(erec(1:ne,:),fullfile(outdir,'trsmR_index.csv'));
fprintf(logf,'E trsmR values: %d shapes, MATLAB X/R == dtrsmR %d/%d\n',ne,sum(erec(1:ne,4)),sum(erec(1:ne,3)));
fe=fopen(fullfile(outdir,'gemvN_out.bin'),'w');assert(fe>0);
erec=zeros(numel(nl)*33,6);ne=0;
for m=nl
 for p=1:33
  X=rand(m,p)-0.5;bv=rand(p,1)-0.5;y=rand(m,1)-0.5;
  g0=kp1320('gemv',0,X,bv,0,0,0);g1=kp1320('gemv2',0,-1,X,bv,1,y);
  fm=X*bv;
  fwrite(fe,X(:),'double');fwrite(fe,bv(:),'double');fwrite(fe,y(:),'double');fwrite(fe,g0(:),'double');fwrite(fe,g1(:),'double');
  ne=ne+1;erec(ne,:)=[m p m sum(bits(fm)==bits(g0)) sum(bits(y-fm)==bits(g1)) chk(X)];
 end
end
fclose(fe);
writematrix(erec(1:ne,:),fullfile(outdir,'gemvN_index.csv'));
fprintf(logf,'E gemvN values: %d shapes, MATLAB X*b == dgemvN %d/%d, y-X*b == fused %d\n',ne,sum(erec(1:ne,4)),sum(erec(1:ne,3)),sum(erec(1:ne,5)));
fe=fopen(fullfile(outdir,'syrk_out.bin'),'w');assert(fe>0);
erec=zeros(32*3,8);ne=0;
for p=1:32
 for rep=1:3
  A=rand(p)-0.5;
  if rep>=2;A=triu(A)+diag(1+rand(p,1));end
  SU=kp1320('syrk',0,A);SL=kp1320('syrk',1,A);G=kp1320('gemm',0,1,1,A,A,0,zeros(p));
  Cm=A*A';
  mu=triu(true(p));ml=tril(true(p));
  fwrite(fe,A(:),'double');fwrite(fe,SU(:),'double');fwrite(fe,SL(:),'double');fwrite(fe,G(:),'double');fwrite(fe,Cm(:),'double');
  ne=ne+1;erec(ne,:)=[p rep p*(p+1)/2 sum(bits(Cm(mu))==bits(SU(mu))) sum(bits(Cm(ml))==bits(SL(ml))) p*p sum(bits(Cm)==bits(G)) chk(A)];
 end
end
fclose(fe);
writematrix(erec(1:ne,:),fullfile(outdir,'syrk_index.csv'));
fprintf(logf,'E syrk values: A*A'' == syrkU %d syrkL %d of %d ; == gemmNT %d/%d\n',sum(erec(1:ne,4)),sum(erec(1:ne,5)),sum(erec(1:ne,3)),sum(erec(1:ne,7)),sum(erec(1:ne,6)));
catch err
 failed=true;fprintf(logf,'SECTION E FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

% ---------------- F. tcdf grid ----------------
try
rng(132006,'twister');
ft=fopen(fullfile(outdir,'tcdf_out.bin'),'w');assert(ft>0);
nt=0;
for dfe=1:130
 u=rand(48,1);
 tv=-[8*u(1:16);3*u(17:32);40*u(33:40).^3;1e-3*u(41:48)];
 P=tcdf(tv,dfe);
 fwrite(ft,tv,'double');fwrite(ft,P,'double');
 nt=nt+numel(tv);
end
fclose(ft);
fprintf(logf,'F tcdf: %d values\n',nt);
catch err
 failed=true;fprintf(logf,'SECTION F FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- G. unchanged robustfit next to the public-API twin ----------------
try
rng(132007,'twister');
ns=[20 33 48 49 64 80 97 130];
ks=[1 2 3 4 5 7 8 9 12 15 16 24 31];
fields={'ols_s','robust_s','mad_s','s','resid','rstud','se','covb','coeffcorr','t','p','w','Qy','R','dfe','h','Rtol'};
NF=numel(fields);
grec=zeros(numel(ns)*numel(ks)*7,12+2*(NF+1));ng=0;gerr={};
for n=ns
 for k=ks
  p=k+1;
  if n<p+6;continue;end
  for fam=1:7
   if fam>=6&&~(any(n==[33 64])&&any(k==[2 5 9]));continue;end
   Xin=rand(n,k)-0.5;beta=rand(k,1)-0.5;noise=rand(n,1)-0.5;extra=rand(n,1);
   if fam==3
    for j=2:k;Xin(:,j)=0.7*Xin(:,j-1)+0.3*Xin(:,j);end
   elseif fam==4
    Xin=Xin.*pow2(mod(3*(0:k-1),9)-4);
   end
   y=1+Xin*beta+0.2*noise;
   if fam==2
    ix=1:7:n;y(ix)=y(ix)+6*(1+extra(ix));
   elseif fam==4
    y(n-2:n)=y(n-2:n)+[5;-7;9];
   elseif fam==5
    y=1+Xin*beta+4*noise.^3+10*(extra<0.08).*(extra-0.04);
   elseif fam==6
    Xin(:,k)=Xin(:,1);
   elseif fam==7
    Xin=round(8*Xin);y=1+Xin*round(4*beta);
    y(1:9:n)=y(1:9:n)+3;
   end
   id=sprintf('%d_%d_%d',n,k,fam);
   D=put(D,['g_X_' id],Xin);D=put(D,['g_y_' id],y);
   row=zeros(1,12+2*(NF+1));row(1:3)=[n k fam];
   try
    lastwarn('');
    [bg,sg]=robustfit(Xin,y);
    [wm,wid]=lastwarn;
    [bg2,sg2]=robustfit(Xin,y);
    row(4)=double(~isempty(wm));
    if ~isempty(wm);gerr{end+1}=struct('id',id,'what','genuine_warning','msg',[wid ' | ' wm]);end %#ok<AGROW>
    D=put(D,['g_b_' id],bg);
    same=isequal(bits(bg),bits(bg2));
    for fi=1:NF
     D=put(D,['g_s_' fields{fi} '_' id],sg.(fields{fi}));
     same=same&&isequal(bits(sg.(fields{fi})),bits(sg2.(fields{fi})));
    end
    row(5)=double(same);
   catch e1
    row(4)=-1;gerr{end+1}=struct('id',id,'what','genuine_error','msg',e1.message); %#ok<AGROW>
    bg=[];sg=[];
   end
   try
    lastwarn('');
    [bt,st,tr]=rf_twin(Xin,y);
    wt=lastwarn;
    row(6)=tr.iter;row(7)=double(tr.limit);row(8)=tr.xrank;row(9)=double(~isempty(wt));
    D=put(D,['t_Q_' id],tr.Q);D=put(D,['t_R_' id],tr.R);D=put(D,['t_perm_' id],tr.perm);
    D=put(D,['t_binit_' id],tr.binit);D=put(D,['t_E_' id],tr.E);D=put(D,['t_h_' id],tr.h);
    D=put(D,['t_scal_' id],[tr.ols_s;tr.tiny_s;tr.tol]);
    D=put(D,['t_B_' id],tr.B);D=put(D,['t_S_' id],tr.S);D=put(D,['t_W_' id],tr.W);D=put(D,['t_U_' id],tr.U);
    D=put(D,['t_wxrank_' id],tr.wxrank);D=put(D,['t_r1_' id],tr.r1);
    D=put(D,['t_b_' id],bt);
    if isfield(tr,'RI');D=put(D,['t_RI_' id],tr.RI);D=put(D,['t_tempC_' id],tr.tempC);end
    if ~isempty(bg)
     row(13)=numel(bg);row(14)=sum(bits(bg)==bits(bt));
     for fi=1:NF
      g=sg.(fields{fi});tw=st.(fields{fi});
      row(13+2*fi)=numel(g);
      if isequal(size(g),size(tw));row(14+2*fi)=sum(bits(g)==bits(tw));end
     end
    end
   catch e2
    row(6)=-1;gerr{end+1}=struct('id',id,'what','twin_error','msg',getReport(e2,'basic','hyperlinks','off')); %#ok<AGROW>
   end
   try
    V1320_CB={};
    [bc,~]=robustfit(Xin,y,@cb_bisquare,4.685);
    row(10)=numel(V1320_CB);
    if ~isempty(bg);row(11)=sum(bits(bc)==bits(bg));end
    if row(6)>0
     nu=min(numel(V1320_CB),size(tr.U,2));e=0;
     for q=1:nu;e=e+sum(bits(V1320_CB{q})==bits(tr.U(:,q)));end
     row(12)=e;
    end
    Ucb=zeros(n,numel(V1320_CB));for q=1:numel(V1320_CB);Ucb(:,q)=V1320_CB{q};end
    D=put(D,['g_cbU_' id],Ucb);
   catch e3
    row(10)=-1;gerr{end+1}=struct('id',id,'what','callback_error','msg',e3.message); %#ok<AGROW>
   end
   ng=ng+1;grec(ng,:)=row;
  end
 end
end
writematrix(grec(1:ng,:),fullfile(outdir,'robustfit_index.csv'));
writeJson(fullfile(outdir,'robustfit_notes.json'),struct('fields',{fields},'notes',{gerr}));
g=grec(1:ng,:);
fprintf(logf,'G robustfit: %d cohorts, genuine errors %d, genuine warnings %d, repeat-identical %d, twin errors %d\n',ng,sum(g(:,4)==-1),sum(g(:,4)==1),sum(g(:,5)),sum(g(:,6)==-1));
fprintf(logf,' twin == genuine b: %d/%d\n',sum(g(:,14)),sum(g(:,13)));
for fi=1:NF;fprintf(logf,' twin == genuine %s: %d/%d\n',fields{fi},sum(g(:,14+2*fi)),sum(g(:,13+2*fi)));end
fprintf(logf,' callback b == default b: %d/%d ; callback u == twin u: %d words over %d cohorts\n',sum(g(:,11)),sum(g(:,13)),sum(g(:,12)),ng);
catch err
 failed=true;fprintf(logf,'SECTION G FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
fprintf(logf,'t=%.1f\n',toc(tStart));

fclose(D.fid);
writeJson(fullfile(outdir,'dump_index.json'),struct('records',{D.index}));
fprintf(logf,'dump done, %d doubles\n',D.pos);
assert(~failed,'a V1320 probe section failed; see out/log.txt');
end

function [b,stats,tr]=rf_twin(Xin,y)
% Public-API twin of a default robustfit(X,y) call (bisquare, tune 4.685, constant term),
% written for this probe from the documented algorithm. Every stage is kept in tr.
tune=4.685;
[n,k]=size(Xin);X=[ones(n,1) Xin];p=k+1;
[Q,R,perm]=qr(X,0);
tol=abs(R(1))*max(n,p)*eps(class(R));
xrank=sum(abs(diag(R))>tol);
tr=struct('Q',Q,'R',R,'perm',perm,'tol',tol,'xrank',xrank,'limit',false);
if xrank==p
 b(perm,:)=R\(Q'*y);
else
 b(perm,:)=[R(1:xrank,1:xrank)\(Q(:,1:xrank)'*y);zeros(p-xrank,1)];
 perm=perm(1:xrank);
end
tr.binit=b;
b0=zeros(size(b));
E=X(:,perm)/R(1:xrank,1:xrank);
h=min(.9999,sum(E.*E,2));
adjfactor=1./sqrt(1-h);
dfe=n-xrank;
ols_s=norm(y-X*b)/sqrt(dfe);
tiny_s=1e-6*std(y);
if tiny_s==0;tiny_s=1;end
tr.E=E;tr.h=h;tr.ols_s=ols_s;tr.tiny_s=tiny_s;
Dtol=sqrt(eps(class(X)));
iter=0;iterlim=50;wxrank=xrank;
tr.B=zeros(p,0);tr.S=zeros(1,0);tr.W=zeros(n,0);tr.U=zeros(n,0);tr.wxrank=zeros(1,0);tr.r1=y-X*b;
w=ones(n,1);
while (iter==0)||any(abs(b-b0)>Dtol*max(abs(b),abs(b0)))
 iter=iter+1;
 if iter>iterlim
  tr.limit=true;
  break;
 end
 r=y-X*b;
 radj=r.*adjfactor;
 s=madsigma_twin(radj,wxrank);
 u=radj/(max(s,tiny_s)*tune);
 w=bisquare_twin(u);
 b0=b;
 [b(perm),wxrank]=wfit_twin(y,X(:,perm),w);
 tr.B(:,end+1)=b;tr.S(end+1)=s;tr.W(:,end+1)=w;tr.U(:,end+1)=u;tr.wxrank(end+1)=wxrank;
end
tr.iter=iter;
r=y-X*b;
radj=r.*adjfactor;
mad_s=madsigma_twin(radj,xrank);
if all(w<Dtol|w>1-Dtol)
 included=(w>1-Dtol);
 robust_s=norm(r(included))/sqrt(sum(included)-xrank);
else
 robust_s=sigma_twin(radj,xrank,max(mad_s,tiny_s),tune,h);
end
sigma=max(robust_s,sqrt((ols_s^2*xrank^2+robust_s^2*n)/(xrank^2+n)));
RI=R(1:xrank,1:xrank)\eye(xrank);
tempC=(RI*RI')*sigma^2;
tempse=sqrt(max(eps(class(tempC)),diag(tempC)));
tr.RI=RI;tr.tempC=tempC;
C=NaN(p,p);covb=zeros(p,p);se=zeros(p,1);
covb(perm,perm)=tempC;
C(perm,perm)=tempC./(tempse*tempse');
se(perm)=tempse;
stats.ols_s=ols_s;
stats.robust_s=robust_s;
stats.mad_s=mad_s;
stats.s=sigma;
stats.resid=r;
stats.rstud=r.*adjfactor/sigma;
stats.se=se;
stats.covb=covb;
stats.coeffcorr=C;
stats.t=NaN(size(b));
stats.t(se>0)=b(se>0)./se(se>0);
stats.p=2*tcdf(-abs(stats.t),dfe);
stats.w=w;
z=zeros(p,1);z(perm)=Q(:,1:xrank)'*y;
stats.Qy=z;
Rz=zeros(p,p);Rz(perm,perm)=R(1:xrank,1:xrank);
stats.R=Rz;
stats.dfe=dfe;
stats.h=h;
stats.Rtol=tol;
end

function s=madsigma_twin(r,p)
rs=sort(abs(r));
s=median(rs(max(1,p):end))/0.6745;
end

function w=bisquare_twin(r)
w=(abs(r)<1).*(1-r.^2).^2;
end

function [b,r]=wfit_twin(y,x,w)
n=size(x,2);
sw=sqrt(w);
yw=y.*sw;
xw=x.*sw(:,ones(1,n));
[b,r]=linsolve(xw,yw,struct('RECT',true));
end

function s=sigma_twin(r,p,s,t,h)
st=s*t;
n=length(r);
u=r./st;
phi=u.*bisquare_twin(u);
delta=0.0001;
u1=u-delta;
phi0=u1.*bisquare_twin(u1);
u1=u+delta;
phi1=u1.*bisquare_twin(u1);
dphi=(phi1-phi0)./(2*delta);
m1=mean(dphi);
m2=sum((1-h).*phi.^2)/(n-p);
K=1+(p/n)*(1-m1)/m1;
s=K*sqrt(m2)*st/(m1);
end

function w=cb_bisquare(r)
global V1320_CB %#ok<GVMIS>
V1320_CB{end+1}=r;
w=(abs(r)<1).*(1-r.^2).^2;
end

function v=pick(A,mask)
v=A(mask);
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
