function run_original_v244()
% V244 genuine MathWorks original-only source-DISCLOSED multivariate
% weighted QR numeric stage on all twelve p=2 predictor V211 cases.
% No MathWorks source code, runtime internal variable names or current
% coefficient values imported. User-written bisquare callback only records
% its own genuine MATLAB u/w values. Separately measured public A\y and
% full economy QR at EACH original IRLS stage, on approved AMD R2026b.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND'));
assert(raw.seed==202611220211 && numel(raw.cases)==48);
global CINGULUM_V244_CALLBACKS;
rows=struct('id',{},'rep',{},'n',{},'p',{},...
 'original_full_b_hex',{},'original_full_17_fields_equal_custom',{},...
 'original_raw_QR_pivot_one_based',{},'original_callback_count',{},...
 'original_IRLS_steps',{});
for rep=1:2
 for index=1:48
  c=raw.cases(index);
  if double(c.p)~=2,continue;end
  n=double(c.n);p=3;
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,2);
  y=hex2num(char(c.y_hex));y=y(:);
  A=[ones(n,1),X];
  [borig,so]=robustfit(X,y);
  CINGULUM_V244_CALLBACKS={};
  [bcustom,sc]=robustfit(X,y,@record_bisquare,4.685);
  assert(isequal(num2hex(borig),num2hex(bcustom)));
  fields=fieldnames(so);
  assert(numel(fields)==17);
  equal=true;
  for j=1:numel(fields)
   name=fields{j};
   equal=equal && isequal(num2hex(so.(name)),num2hex(sc.(name)));
  end
  assert(equal);
  calls=CINGULUM_V244_CALLBACKS;
  steps=numel(calls)-3;
  assert(steps>0 && steps<=50);
  [~,~,original_pivot]=qr(A,'econ','vector');
  assert(isequal(sort(original_pivot),1:p));
  stages=cell(steps,1);
  for iter=1:steps
   w=calls{iter}.w;
   sw=sqrt(w);
   WX=A(:,original_pivot).*sw;
   Wy=y.*sw;
   [Qw,Rw,pivot_w]=qr(WX,'econ','vector');
   tmp=zeros(p,1);tmp(pivot_w)=Rw\(Qw'*Wy);
   bq=zeros(p,1);bq(original_pivot)=tmp;
   backslash_b=zeros(p,1);
   backslash_b(original_pivot)=WX\Wy;
   stages{iter}=struct('stage_ordinal',iter,...
    'source_original_callback_u_hex',{calls{iter}.u_hex},...
    'source_original_callback_w_hex',{calls{iter}.w_hex},...
    'original_weighted_Q_colmajor_hex',{bits(Qw)},...
    'original_weighted_R_pivot_colmajor_hex',{bits(Rw)},...
    'original_weighted_Qy_pivot_hex',{bits(Qw'*Wy)},...
    'original_weighted_QR_pivot_one_based',pivot_w,...
    'original_explicit_QR_b_hex',{bits(bq)},...
    'original_public_weighted_backslash_b_hex',{bits(backslash_b)});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',2,...
   'original_full_b_hex',{bits(borig)},...
   'original_full_17_fields_equal_custom',equal,...
   'original_raw_QR_pivot_one_based',original_pivot,...
   'original_callback_count',numel(calls),...
   'original_IRLS_steps',{stages}); %#ok<AGROW>
 end
end
assert(numel(rows)==24);
for j=1:12
 a=rmfield(rows(j),'rep');b=rmfield(rows(j+12),'rep');
 assert(isequal(a,b),'original weighted QR stage not repeated bitwise');
end
result=struct('classification','V244_SOURCE_DISCLOSED_ORIGINAL_MATHWORKS_P2_EVERY_WEIGHTED_QR_STAGE',...
 'run',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_disclosed',true,'new_first_original_blind_certificate',false,...
 'original_unmodified_robustfit',true,...
 'proprietary_MathWorks_source_or_private_local_names_exported',false,...
 'input_sha256','5836d8f460b64c889feda69ee69dc4792a5ff85bf120600f346171150eb2a559',...
 'cohorts',12,'repetitions',2,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(result));
end
function w=record_bisquare(u)
global CINGULUM_V244_CALLBACKS;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_V244_CALLBACKS{end+1}=struct('u',u,'w',w,...
 'u_hex',{bits(u)},'w_hex',{bits(w)});
end
function out=bits(v)
out=cellstr(num2hex(double(v(:))));
end
