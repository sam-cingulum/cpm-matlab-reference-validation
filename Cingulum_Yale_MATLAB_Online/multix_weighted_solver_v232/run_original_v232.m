function run_original_v232()
% V232 source-DISCLOSED original-only MATLAB R2026b candidate weighted solves.
% All inputs are the same raw V211 X/y, no prior MATLAB numeric values
% imported. Each original/default robustfit call remains untouched.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND'));
assert(raw.seed==202611220211 && numel(raw.cases)==48);
global CINGULUM_V232_CALLBACKS;
rows=struct('id',{},'n',{},'p',{},'rep',{},...
 'original_vs_instrumented_b_exact',{},'original_vs_instrumented_stats_exact',{},...
 'source_first_u_hex',{},'source_first_w_hex',{},...
 'source_second_u_hex',{},'custom_callback_calls',{},'original_final_b_hex',{},...
 'candidate_b',{});
for rep=1:2
 for index=1:48
  c=raw.cases(index);
  if double(c.n)~=33 || ~startsWith(c.id,'v211_dense_')
    continue
  end
  n=double(c.n);p=double(c.p)+1;
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,p-1);
  y=hex2num(char(c.y_hex));y=y(:);
  A=[ones(n,1),X];
  [borig,sorig]=robustfit(X,y);
  CINGULUM_V232_CALLBACKS={};
  [bc,sc]=robustfit(X,y,@capture_bisquare,4.685);
  observed=CINGULUM_V232_CALLBACKS;
  assert(numel(observed)>=2);
  assert(isequal(num2hex(borig),num2hex(bc)),'callback does not preserve original beta');
  names=fieldnames(sorig);
  assert(numel(names)==17);
  fields_exact=true;
  for i=1:numel(names)
   k=names{i};
   fields_exact=fields_exact && isequal(num2hex(sorig.(k)),num2hex(sc.(k)));
  end
  assert(fields_exact,'callback does not preserve original full stats');
  w=hex2num(char(observed{1}.w_hex));w=w(:);
  sw=sqrt(w);
  WX=A.*sw;WY=y.*sw;
  [Q,R,perm]=qr(WX,'econ','vector');
  assert(isequal(size(Q),[n,p]) && isequal(size(R),[p,p]));
  [Q0,R0,pivot0]=qr(A,'econ','vector');
  b0=zeros(p,1);
  b0(pivot0)=R0\(sorig.Qy(pivot0));
  residual_raw=y-A*b0;
  residual_weighted=WY-WX*b0;
  candidate=struct();
  candidate.weighted_public_backslash_hex=bits(WX\WY);
  candidate.lscov_raw_weights_hex=bits(lscov(A,y,w));
  candidate.lscov_preweighted_hex=bits(lscov(WX,WY));
  candidate.normal_equations_hex=bits((WX'*WX)\(WX'*WY));
  candidate.normal_equations_raw_weights_hex=bits((A'*(A.*w))\(A'*(w.*y)));
  bweighted=zeros(p,1);
  bweighted(perm)=R\(Q'*WY);
  candidate.explicit_pivot_Q_R_hex=bits(bweighted);
  candidate.unpivot_Q_R_hex=bits(qr_solve_unpivot(WX,WY));
  candidate.public_weighted_delta_raw_hex=bits(b0+WX\(residual_raw.*sw));
  candidate.public_weighted_delta_WX_hex=bits(b0+WX\residual_weighted);
  correct_pivot=zeros(p,1);
  correct_pivot(perm)=R\(Q'*residual_weighted);
  candidate.explicit_weighted_delta_hex=bits(b0+correct_pivot);
  candidate.lscov_delta_raw_hex=bits(b0+lscov(A,residual_raw,w));
  candidate.lscov_delta_preweighted_hex=bits(b0+lscov(WX,residual_weighted));
  candidate.src_initial_R_Qy_hex=bits(b0);
  rows(end+1)=struct('id',c.id,'n',n,'p',p-1,'rep',rep,...
   'original_vs_instrumented_b_exact',true,...
   'original_vs_instrumented_stats_exact',fields_exact,...
   'source_first_u_hex',{observed{1}.u_hex},...
   'source_first_w_hex',{observed{1}.w_hex},...
   'source_second_u_hex',{observed{2}.u_hex},...
   'custom_callback_calls',numel(observed),...
   'original_final_b_hex',{bits(borig)},'candidate_b',candidate); %#ok<AGROW>
 end
end
assert(numel(rows)==8);
for i=1:4
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+4),'rep');
 assert(isequal(a,b),'V232 original candidate solvers not repeatable');
end
result=struct('classification','V232_SOURCE_DISCLOSED_MATHWORKS_MULTI_X_WEIGHTED_SOLVERS_ORIGINAL_ONLY',...
 'source_disclosed',true,'new_first_blind_certificate',false,...
 'original_unmodified_default_robustfit',true,'run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),'repetitions',2,...
 'original_input_sha256','5836d8f460b64c889feda69ee69dc4792a5ff85bf120600f346171150eb2a559',...
 'rows',rows);
file=fopen(fullfile(root,'original.json'),'w');assert(file>0);
cleanup=onCleanup(@()fclose(file));
fprintf(file,'%s\n',jsonencode(result));
end
function result=qr_solve_unpivot(X,y)
 [Q,R]=qr(X,0);
 result=R\(Q'*y);
end
function w=capture_bisquare(u)
global CINGULUM_V232_CALLBACKS;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_V232_CALLBACKS{end+1}=struct('u_hex',{bits(u)},'w_hex',{bits(w)});
end
function b=bits(v)
b=cellstr(num2hex(double(v(:))));
end
