function run_v1358()
% V1358 original-only semantics probe (source-DISCLOSED diagnostic).
% Records what genuine MATLAB R2026b Update 1 does, bit for bit and word for word, for the
% X\B and robustfit inputs the Rust engine does not yet model:
%  A. warnings: how evalc captures them, and the tol text at extreme scales;
%  B. robustfit: a design of rank 1 (all-zero or constant predictor), NaN and Inf in X or y,
%     too few rows, duplicated columns, logical and single inputs;
%  C. X\B: square (LU) and near-singular systems, wide systems, empty operands, NaN and Inf,
%     negative zeros, single, integer and logical operands, scalars.
% Every record holds the outputs (class, size and the raw bits in hex), the text evalc
% captured, lastwarn, and any error identifier and message. Synthetic seeded inputs only.
% Reads no Rust forecast and no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
prov=struct('classification','V1358_ORIGINAL_ONLY_SEMANTICS_PROBE_SOURCE_DISCLOSED_DIAGNOSTIC', ...
 'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(f,'%s\n',jsonencode(prov));fclose(f);
warning('off','backtrace');
out=fopen(fullfile(outdir,'records.jsonl'),'w');assert(out>0);
closeOut=onCleanup(@()fclose(out));
R=@(label,fn,ins) record(out,label,fn,ins);

% ---------------- A. warnings ----------------
rng(135801,'twister');
for s=[1 1e-100 1e-200 1e-300 1e100 1e200 1e300]
 X=(rand(20,4)-0.5)*s;X(:,4)=X(:,1)+X(:,2);B=rand(20,2)-0.5;
 R(sprintf('A xb rankdef scale %g',s),@()X\B,{X,B});
end
R('A xb zero matrix',@()zeros(10,3)\ones(10,2),{zeros(10,3),ones(10,2)});
X=rand(30,5)-0.5;X(:,5)=0;R('A xb zero column',@()X\ones(30,1),{X,ones(30,1)});
X=rand(30,5)-0.5;X(:,[2 4])=X(:,[1 3]);R('A xb two deficient',@()X\(rand(30,3)-0.5),{X});
% two warnings in one statement
X=rand(12,3)-0.5;X(:,3)=X(:,1);R('A two solves',@()[X\ones(12,1); X\ones(12,1)],{X});

% ---------------- B. robustfit ----------------
rng(135802,'twister');
y=rand(40,1)-0.5;
R('B rf all-zero predictor',@()rf(zeros(40,1),y),{zeros(40,1),y});
R('B rf constant predictor',@()rf(3*ones(40,1),y),{3*ones(40,1),y});
X=rand(40,3)-0.5;X(:,2)=0;R('B rf zero column of three',@()rf(X,y),{X,y});
X=rand(40,2)-0.5;X(:,2)=X(:,1);R('B rf duplicated columns',@()rf(X,y),{X,y});
X=rand(40,2)-0.5;Xn=X;Xn(5,1)=NaN;R('B rf NaN in X',@()rf(Xn,y),{Xn,y});
yn=y;yn([3 17])=NaN;R('B rf NaN in y',@()rf(X,yn),{X,yn});
Xn=X;Xn(1:38,1)=NaN;R('B rf NaN leaves 2 rows',@()rf(Xn,y),{Xn,y});
Xi=X;Xi(4,2)=Inf;R('B rf Inf in X',@()rf(Xi,y),{Xi,y});
yi=y;yi(9)=-Inf;R('B rf Inf in y',@()rf(X,yi),{X,yi});
R('B rf rows equal coefficients',@()rf(X(1:3,:),y(1:3)),{X(1:3,:),y(1:3)});
R('B rf rows below coefficients',@()rf(X(1:2,:),y(1:2)),{X(1:2,:),y(1:2)});
R('B rf one row',@()rf(X(1,:),y(1)),{X(1,:),y(1)});
R('B rf empty',@()rf(zeros(0,1),zeros(0,1)),{});
R('B rf row vector y',@()rf(X,y'),{X,y'});
R('B rf row vector X',@()rf((1:40),y),{(1:40),y});
R('B rf single',@()rf(single(X),single(y)),{single(X),single(y)});
R('B rf logical X',@()rf(rand(40,1)>0.5,y),{});
R('B rf int32 y',@()rf(X,int32(round(10*y))),{});
R('B rf perfect fit',@()rf(X,X*[2;-1]+1),{X});
R('B rf constant y',@()rf(X,ones(40,1)),{X});
R('B rf zero y',@()rf(X,zeros(40,1)),{X});
R('B rf negative zero y',@()rf(X,-zeros(40,1)),{X});
R('B rf all-zero predictor zero y',@()rf(zeros(40,1),zeros(40,1)),{});
R('B rf two all-zero predictors',@()rf(zeros(40,2),y),{});

% ---------------- C. X\B ----------------
rng(135803,'twister');
A=rand(6,6)-0.5;b=rand(6,2)-0.5;
R('C square',@()A\b,{A,b});
As=A;As(:,6)=As(:,1)+As(:,2);R('C square singular',@()As\b,{As,b});
An=A;An(:,6)=An(:,1)+An(:,2)+1e-13*An(:,3);R('C square near singular',@()An\b,{An,b});
R('C square zero',@()zeros(4)\ones(4,1),{});
U=triu(A);R('C upper triangular',@()U\b,{U,b});
L=tril(A);R('C lower triangular',@()L\b,{L,b});
S=A+A'+6*eye(6);R('C symmetric positive definite',@()S\b,{S,b});
R('C symmetric indefinite',@()(A+A')\b,{A+A',b});
W=rand(4,7)-0.5;bw=rand(4,2)-0.5;R('C wide',@()W\bw,{W,bw});
Wd=W;Wd(:,7)=Wd(:,1);R('C wide rank deficient',@()Wd\bw,{Wd,bw});
R('C empty rows',@()zeros(0,3)\zeros(0,2),{});
R('C empty cols',@()zeros(5,0)\ones(5,2),{});
R('C empty rhs',@()(rand(5,3)-0.5)\zeros(5,0),{});
R('C size mismatch',@()ones(5,3)\ones(4,1),{});
X=rand(20,3)-0.5;Bn=rand(20,2)-0.5;Bn(4,1)=NaN;R('C NaN in B',@()X\Bn,{X,Bn});
Xn=X;Xn(2,2)=NaN;R('C NaN in X',@()Xn\Bn,{Xn});
Xi=X;Xi(7,1)=Inf;R('C Inf in X',@()Xi\(rand(20,1)-0.5),{Xi});
Bi=rand(20,1)-0.5;Bi(3)=Inf;R('C Inf in B',@()X\Bi,{X,Bi});
Bz=zeros(20,2);Bz(5,1)=-0;Bz(:,2)=-0;R('C negative zeros in B',@()X\Bz,{X,Bz});
Xz=X;Xz(:,2)=-Xz(:,2);Xz(1,2)=-0;R('C negative zero in X',@()Xz\(rand(20,1)-0.5),{Xz});
R('C single',@()single(X)\single(Bn(:,2)),{});
R('C mixed single double',@()single(X)\Bn(:,2),{});
R('C int32',@()int32(round(10*X))\int32(ones(20,1)),{});
R('C int32 double',@()int32(round(10*X))\ones(20,1),{});
R('C logical',@()(X>0)\ones(20,1),{});
R('C scalar',@()4\[2 3],{});
R('C scalar zero',@()0\[2 -3 0],{});
R('C vector by scalar',@()[1;2;3]\6,{});
R('C sparse',@()sparse(X)\Bn(:,2),{});
fprintf('done\n');
end

function out=rf(X,y)
[b,s]=robustfit(X,y);
names=fieldnames(s);
out=cell(1,1+numel(names));out{1}=b;
for q=1:numel(names);out{1+q}=s.(names{q});end
end

function record(f,label,fn,ins) %#ok<INUSD>
r=struct('label',label,'text','','last_id','','last_msg','','err_id','','err_msg','','outs',{{}},'fields',{{}});
lastwarn('','');
try
 txt=evalc('o=fn();');
 r.text=txt;
 if ~iscell(o);o={o};end
 r.outs=cellfun(@enc,o,'UniformOutput',false);
catch e
 r.err_id=e.identifier;r.err_msg=e.message;
end
[m,id]=lastwarn;r.last_id=id;r.last_msg=m;
if startsWith(label,'B rf')&&isempty(r.err_id)
 [~,s]=robustfit(zeros(5,1)+(1:5)',(1:5)');r.fields=fieldnames(s)';
end
fprintf(f,'%s\n',jsonencode(r));
end

function e=enc(v)
e=struct('class',class(v),'size',size(v),'issparse',issparse(v),'hex','');
if issparse(v);v=full(v);end
switch class(v)
 case 'double';e.hex=strjoin(cellstr(dec2hex(typecast(v(:),'uint64'),16)),'');
 case 'single';e.hex=strjoin(cellstr(dec2hex(typecast(v(:),'uint32'),8)),'');
 case 'logical';e.hex=sprintf('%d',v(:));
 otherwise
  if isinteger(v);e.hex=strjoin(arrayfun(@(x)sprintf('%d',x),v(:),'UniformOutput',false),',');end
end
end
