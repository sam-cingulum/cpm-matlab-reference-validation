function run_v1300()
% V1300 original-only kernel path probe (source-DISCLOSED diagnostic, not firstblind).
% Asks genuine MATLAB R2026b Update 1 three questions:
%   1. Which BLAS/LAPACK build does it load, and in which CBWR mode?
%   2. Which public LAPACK routine sequence reproduces hidden X\B bit for bit
%      on the already disclosed V1224 inputs?
%   3. What summation trees do the BLAS kernels under that sequence use?
% It reads no Rust forecast and no earlier MATLAB numerical output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));

% ---------------- 1. provenance ----------------
prov=struct();
prov.classification='V1300_ORIGINAL_ONLY_KERNEL_PATH_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC';
prov.V12='SEALED';
prov.release=version;
prov.blas=version('-blas');
prov.lapack=version('-lapack');
prov.mkl_cbwr=getenv('MKL_CBWR');
prov.blas_version_env=getenv('BLAS_VERSION');
prov.lapack_version_env=getenv('LAPACK_VERSION');
prov.mkl_debug_cpu_type=getenv('MKL_DEBUG_CPU_TYPE');
prov.mkl_enable_instructions=getenv('MKL_ENABLE_INSTRUCTIONS');
prov.run_id=getenv('GITHUB_RUN_ID');
prov.public_commit=getenv('GITHUB_SHA');
prov.matlabroot=matlabroot;
[~,t]=system('lscpu');prov.lscpu=t;
bindir=fullfile(matlabroot,'bin','glnxa64');
[~,t]=system(['ls -la ' bindir ' | grep -iE "mkl|blas|lapack|iomp|flame|blis|aocl|mwmathspec|mwmathlinalg"']);
prov.bin_listing=t;
[~,t]=system(['cd ' bindir ' && sha256sum mkl.so libmwblas.so libmwlapack.so libmwmathspec.so libmwmathlinalg.so 2>&1']);
prov.bin_sha256=t;
pid=feature('getpid');
mapcmd=sprintf('grep -iE "mkl|blas|lapack|iomp|tbb|flame|blis" /proc/%d/maps | awk ''{print $6}'' | sort -u',pid);
[~,t]=system(mapcmd);prov.maps_before=t;
Awarm=reshape(mod((1:280)*7919,97),40,7)+eye(40,7);xw=Awarm\ones(40,3);assert(all(isfinite(xw(:)))); %#ok<NASGU>
[~,t]=system(mapcmd);prov.maps_after_backslash=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
fprintf(logf,'provenance written\nblas=%s\nlapack=%s\n',prov.blas,prov.lapack);

% ---------------- MEX gateway ----------------
try
 mex('-R2018a','-silent','-outdir',outdir,fullfile(root,'kp1300.c'),'-lmwblas','-lmwlapack');
catch err
 fprintf(logf,'MEX build failed: %s\n',getReport(err,'extended','hyperlinks','off'));
 rethrow(err);
end
addpath(outdir);
assert(kp1300('dot',[1 2 3],[4 5 6],0,0)==32);
[~,t]=system(mapcmd);prov.maps_after_mex=t;
writeJson(fullfile(outdir,'provenance.json'),prov);
fprintf(logf,'mex ok\n');

% ---------------- 2. path identification on disclosed V1224 inputs ----------------
s=jsondecode(fileread(fullfile(root,'..','multix_v1225_new_x_b_firstblind','input.json')));
assert(numel(s.cases)==96 && numel(s.matrices)==8);
matIds=string({s.matrices.id});
methods=1:12;offs=[0 1];widths=[1,2,11,12,13,23,24,25];
padding48=[0,2,3,7];padding65=[0,1,2,7];
rec=zeros(96*4*numel(widths)*numel(methods)*numel(offs),10);nr=0;
frec=zeros(96*4*4,7);nf=0;
hid=fopen(fullfile(outdir,'hidden.bin'),'w');assert(hid>0);
for ci=1:96
 c=s.cases(ci);mid=find(matIds==string(c.matrix_id));assert(isscalar(mid));
 m=s.matrices(mid);n=double(m.n);p=double(m.p);
 X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
 b=reshape(hex2num(char(c.b_colmajor_hex)),n,1);
 zvec=padding48;if n==65;zvec=padding65;end
 for z=zvec
  Xp=[X;zeros(z,p)];Yp=[repmat(b,1,25);zeros(z,25)];
  [~,R,P]=qr(Xp,'econ','vector');
  assert(isequal(double(P(:).'),1:p));
  fm=[1 3 4 9];
  for fi=1:4
   F=kp1300('factor',fm(fi),Xp,0);
   Rm=triu(F(1:p,:));
   mask=triu(true(p));
   eqR=sum(bits(Rm(mask))==bits(R(mask)));
   eqNeg=sum(bits(-Rm(mask))==bits(R(mask)));
   nf=nf+1;frec(nf,:)=[ci n p z fm(fi) max(eqR,eqNeg) nnz(mask)];
  end
  for w=widths
   Z=Yp(:,1:w);
   hidden=Xp\Z;
   fwrite(hid,hidden,'double');
   hb=bits(hidden);
   for mi=methods
    for off=offs
     cand=kp1300('solve',mi,Xp,Z,off);
     e=reshape(bits(cand)==hb,p,w);
     nr=nr+1;
     rec(nr,:)=[ci n p z w mi off sum(e(:)) sum(sum(e(1:2,:))) p*w];
    end
   end
  end
 end
end
fclose(hid);
rec=rec(1:nr,:);frec=frec(1:nf,:);
writematrix(rec,fullfile(outdir,'path_id.csv'));
writematrix(frec,fullfile(outdir,'factor_id.csv'));
summary=struct('columns','method off exact_all total_all exact_first2 total_first2','rows',[]);
rows=zeros(numel(methods)*numel(offs),6);k=0;
for mi=methods
 for off=offs
  sel=rec(:,6)==mi & rec(:,7)==off;
  k=k+1;rows(k,:)=[mi off sum(rec(sel,8)) sum(rec(sel,10)) sum(rec(sel,9)) 2*sum(rec(sel,5))];
  fprintf(logf,'solve method %2d off %d: all %d/%d first2 %d/%d\n',rows(k,:));
 end
end
summary.rows=rows;
fsum=zeros(4,3);
for fi=1:4
 sel=frec(:,5)==fm(fi);fsum(fi,:)=[fm(fi) sum(frec(sel,6)) sum(frec(sel,7))];
 fprintf(logf,'factor method %d R words equal to qr(): %d/%d\n',fsum(fi,:));
end
summary.factor_rows=fsum;
writeJson(fullfile(outdir,'path_id_summary.json'),summary);

% ---------------- 3. summation trees (FPRev masks) ----------------
failed=false;
try
uniq=containers.Map('KeyType','char','ValueType','double');
fb=fopen(fullfile(outdir,'fprev.bin'),'w');assert(fb>0);
usize=zeros(0,1);
idx=zeros(400000,8);ni=0;
% kind 1: ddot
for n=1:130
 for offx=0:3
  for offy=0:1
   L=kp1300('fprev_dot',n,offx,offy);
   [uniq,usize,id]=reg(uniq,usize,fb,L);
   ni=ni+1;idx(ni,:)=[1 n 1 1 offx offy 0 id];
  end
 end
end
fprintf(logf,'fprev dot done, unique=%d\n',numel(usize));
% kind 2: dgemv('T')
for m=1:72
 for nc=1:40
  for offA=0:1
   for lde=[0 3]
    L=kp1300('fprev_gemvT',m,nc,offA,0,lde);
    for c=1:nc
     [uniq,usize,id]=reg(uniq,usize,fb,L(:,:,c));
     ni=ni+1;idx(ni,:)=[2 m nc c offA 0 lde id];
    end
   end
  end
 end
end
fprintf(logf,'fprev gemvT done, unique=%d\n',numel(usize));
% kind 4: dlarf('L') inner w=C''v
for m=3:72
 for nc=[1:14 23:26 36 37 40]
  for off=0:1
   L=kp1300('fprev_larf',m,nc,off);
   for c=1:nc
    [uniq,usize,id]=reg(uniq,usize,fb,L(:,:,c));
    ni=ni+1;idx(ni,:)=[4 m nc c off 0 0 id];
   end
  end
 end
end
fprintf(logf,'fprev larf done, unique=%d\n',numel(usize));
% kind 3: dgemv('N') trees across columns
for m=[1 2 3 4 5 8 12 13 16 17 48 65]
 for nc=1:40
  L=kp1300('fprev_gemvN',m,nc);
  for r=1:m
   [uniq,usize,id]=reg(uniq,usize,fb,L(:,:,r));
   ni=ni+1;idx(ni,:)=[3 m nc r 0 0 0 id];
  end
 end
end
fclose(fb);
idx=idx(1:ni,:);
writematrix(idx,fullfile(outdir,'fprev_index.csv'));
writematrix(usize,fullfile(outdir,'fprev_unique_sizes.csv'));
fprintf(logf,'fprev all done, unique=%d probes=%d\n',numel(usize),ni);
catch err
 failed=true;fprintf(logf,'SECTION 3 FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end

% ---------------- 4. raw kernel dumps on seeded synthetic data ----------------
try
rng(1300,'twister');
D=struct('fid',fopen(fullfile(outdir,'dump.bin'),'w'),'index',{{}},'pos',0);assert(D.fid>0);
T=4;
for n=[1:40 47 48 49 50 51 63 64 65 66 67 96 100]
 Xr=randn(n,T).*pow2(randi([-3 3],n,T));Yr=randn(n,T);
 o=zeros(4,T);
 for t=1:T
  o(1,t)=kp1300('dot',Xr(:,t),Yr(:,t),0,0);
  o(2,t)=kp1300('dot',Xr(:,t),Xr(:,t),0,0);
  o(3,t)=kp1300('nrm2',Xr(:,t),0);
  o(4,t)=kp1300('nrm2',Xr(:,t),1);
 end
 D=put(D,sprintf('dot_x_%d',n),Xr);D=put(D,sprintf('dot_y_%d',n),Yr);D=put(D,sprintf('dot_out_%d',n),o);
 a=randn;
 D=put(D,sprintf('axpy_a_%d',n),a);
 D=put(D,sprintf('axpy_out_%d',n),kp1300('axpy',a,Xr(:,1),Yr(:,1)));
 D=put(D,sprintf('scal_out_%d',n),kp1300('scal',a,Xr(:,1)));
 if n>=2
  g=zeros(n+1,T);
  for t=1:T;g(:,t)=kp1300('larfg',Yr(1,t),Xr(2:n,t));end
  D=put(D,sprintf('larfg_out_%d',n),g);
 end
 D=put(D,sprintf('nrm2big_%d',n),[kp1300('fprev_nrm2sq',n,0) kp1300('fprev_nrm2sq',n,1)]);
end
for m=[5 37 46 47 48 49 50 51 62 63 64 65 66 67 72]
 for nc=[1 2 3 4 5 11 12 13 24 25]
  A=randn(m,nc);x=randn(m,1);y=randn(nc,1);al=randn;
  tag=sprintf('%d_%d',m,nc);
  D=put(D,['gemv_A_' tag],A);D=put(D,['gemv_x_' tag],x);
  D=put(D,['gemvT_out_' tag],kp1300('gemv',1,A,x,0,0,0));
  D=put(D,['gemvT_out_off1_' tag],kp1300('gemv',1,A,x,1,0,0));
  D=put(D,['gemvN_y_' tag],y);
  D=put(D,['gemvN_out_' tag],kp1300('gemv',0,A,y,0,0,0));
  D=put(D,['ger_alpha_' tag],al);
  D=put(D,['ger_out_' tag],kp1300('ger',al,x,y,A));
  v=x;v(1)=1;tau=1+0.5*rand;
  D=put(D,['larf_tau_' tag],tau);
  D=put(D,['larf_out_' tag],kp1300('larf',v,tau,A,0));
  D=put(D,['larf_out_off1_' tag],kp1300('larf',v,tau,A,1));
 end
end
for p=2:12
 for w=[1 2 11 12 13 25]
  R=triu(randn(p))+diag(2+rand(p,1));B=randn(p,w);
  tag=sprintf('%d_%d',p,w);
  D=put(D,['tri_R_' tag],R);D=put(D,['tri_B_' tag],B);
  D=put(D,['trsm_out_' tag],kp1300('trsm',R,B));
  D=put(D,['trsv_out_' tag],kp1300('trsv',R,B));
  D=put(D,['trtrs_out_' tag],kp1300('trtrs',R,B));
  D=put(D,['mldivide_out_' tag],R\B);
 end
end
% stage dumps on the first disclosed case of each matrix
seen=strings(0,1);
for ci=1:96
 c=s.cases(ci);
 if any(seen==string(c.matrix_id));continue;end
 seen(end+1)=string(c.matrix_id); %#ok<AGROW>
 mid=find(matIds==string(c.matrix_id));m=s.matrices(mid);n=double(m.n);p=double(m.p);
 X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
 b=reshape(hex2num(char(c.b_colmajor_hex)),n,1);
 for z=[0 7]
  Xp=[X;zeros(z,p)];
  tag=sprintf('case%d_z%d',ci,z);
  [~,R]=qr(Xp,'econ');
  D=put(D,['stage_qrR_' tag],R);
  F1=kp1300('factor',1,Xp,0);F9=kp1300('factor',9,Xp,0);
  D=put(D,['stage_geqp3_' tag],F1);D=put(D,['stage_refgeqr2_' tag],F9);
  for w=[1 2 12 13 25]
   Z=[repmat(b,1,w);zeros(z,w)];
   wt=sprintf('%s_w%d',tag,w);
   D=put(D,['stage_hidden_' wt],Xp\Z);
   D=put(D,['stage_ormqr_' wt],kp1300('applyq',1,F1(1:end-2,:),F1(end-1,:),Z,0));
   D=put(D,['stage_orm2r_' wt],kp1300('applyq',2,F1(1:end-2,:),F1(end-1,:),Z,0));
   D=put(D,['stage_reform2r_' wt],kp1300('applyq',3,F1(1:end-2,:),F1(end-1,:),Z,0));
  end
 end
end
fclose(D.fid);
writeJson(fullfile(outdir,'dump_index.json'),struct('records',{D.index}));
fprintf(logf,'dump done, %d doubles\n',D.pos);
catch err
 failed=true;fprintf(logf,'SECTION 4 FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
end
assert(~failed,'a V1300 probe section failed; see out/log.txt');
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

function [uniq,usize,id]=reg(uniq,usize,fb,L)
m=size(L,1);
L(~isfinite(L))=255;L=min(max(round(L),0),255);
key=[sprintf('%d:',m) char(L(:).'+33)];
if isKey(uniq,key)
 id=uniq(key);
else
 id=numel(usize)+1;
 uniq(key)=id;
 usize(end+1,1)=m;
 fwrite(fb,uint8(L(:)),'uint8');
end
end
