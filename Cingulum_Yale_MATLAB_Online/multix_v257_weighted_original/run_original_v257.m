function run_original_v257()
% V257 genuine R2026b SOURCE-DISCLOSED, AFTER immutable V252 first-blind FAIL.
% All 12 V252 terminal-outlier cohorts. Capture genuine MATLAB original
% PUBLIC weighted QR Q,R,Q'*y/backslash for every native bisquare update.
% Original robustfit unchanged; user-authored callback numeric-only
% observations of coefficient-length finite doubles. Export NO proprietary
% MathWorks source text, NO private runtime variable names.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_V252_R2026B_FULL_17_MULTIX_FIRST_ORIGINAL_BLIND'));
assert(raw.seed==202611220252 && numel(raw.cases)==48);
global V257_OBS V257_COEFF_COUNT V257_CALLBACK_COUNT;
rows=struct('id',{},'rep',{},'n',{},'p',{},...
 'unchanged_original_all_17_fields_equal_user_bisquare',{},...
 'original_B_hex',{},'original_raw_QR_pivot_one_based',{},...
 'original_callback_count',{},'original_IRLS_stages',{});
for rep=1:2
 for index=1:48
  c=raw.cases(index);
  if ~strcmp(c.family,'terminal_outlier'),continue;end
  n=double(c.n);pr=double(c.p);p=pr+1;
  assert(ismember(n,[35 61 87]) && ismember(pr,[2 3 4 5]));
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,pr);
  y=hex2num(char(c.y_hex));y=y(:);
  A=[ones(n,1),X];
  [b0,s0]=robustfit(X,y);
  assert(numel(fieldnames(s0))==17);
  V257_OBS={};V257_COEFF_COUNT=p;V257_CALLBACK_COUNT=0;
  [b1,s1]=robustfit(X,y,@v257_numeric_bisquare,4.685);
  assert(isequal(num2hex(b0),num2hex(b1)));
  names=fieldnames(s0);match=true;
  for k=1:numel(names)
   field=names{k};
   match=match && isequal(num2hex(s0.(field)),num2hex(s1.(field)));
  end
  assert(match,'Original unchanged robustfit must agree with user bisquare in all 17 fields');
  stages=V257_CALLBACK_COUNT-3;
  assert(stages>=1 && stages<=50 && numel(V257_OBS)==V257_CALLBACK_COUNT);
  [~,~,P0]=qr(A,'econ','vector');
  assert(isequal(sort(P0),1:p));
  actual=cell(stages,1);
  for i=1:stages
   observed=V257_OBS{i};
   w=observed.w;
   assert(numel(w)==n && all(isfinite(w)) && all(w>=0) && all(w<=1));
   sw=sqrt(w);
   WX=A(:,P0).*sw;
   Wy=y.*sw;
   [Q,Rw,Pw]=qr(WX,'econ','vector');
   assert(isequal(sort(Pw),1:p));
   Qy=Q'*Wy;
   candidate_from_backslash=zeros(p,1);
   candidate_from_backslash(P0)=WX\Wy;
   tmp=zeros(p,1);tmp(Pw)=Rw\Qy;
   candidate_from_explicit=zeros(p,1);
   candidate_from_explicit(P0)=tmp;
   if i<stages
    next=V257_OBS{i+1}.current;
   else
    next=b0;
   end
   assert(numel(next)==p && isreal(next) && all(isfinite(next)));
   actual{i}=struct('ordinal',i,'source_original_weight_hex',{bits(w)},...
    'original_genuine_hidden_next_b_hex',{bits(next)},...
    'source_public_weighted_Q_colmajor_hex',{bits(Q)},...
    'source_public_weighted_R_pivot_colmajor_hex',{bits(Rw)},...
    'source_public_weighted_Qy_pivot_hex',{bits(Qy)},...
    'source_weighted_QR_pivot_one_based',Pw,...
    'source_public_weighted_backslash_b_hex',{bits(candidate_from_backslash)},...
    'source_public_explicit_QR_b_hex',{bits(candidate_from_explicit)});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',pr,...
   'unchanged_original_all_17_fields_equal_user_bisquare',match,...
   'original_B_hex',{bits(b0)},...
   'original_raw_QR_pivot_one_based',P0,...
   'original_callback_count',V257_CALLBACK_COUNT,...
   'original_IRLS_stages',{actual}); %#ok<AGROW>
 end
end
assert(numel(rows)==24);
for j=1:12
 a=rmfield(rows(j),'rep');b=rmfield(rows(j+12),'rep');
 assert(isequal(a,b),'original public weighted QR numeric stages must repeat bitwise');
end
out=struct('classification','V257_SOURCE_DISCLOSED_ORIGINAL_MATHWORKS_WEIGHTED_QR_ALL_TERMINAL_OUTLIER',...
 'run',getenv('GITHUB_RUN_ID'),'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_disclosed',true,'new_original_first_source_unseen_certificate',false,...
 'prior_first_original_blind_V252_verdict','FAIL',...
 'original_unchanged_robustfit',true,'original_proprietary_source_exported',false,...
 'original_private_caller_variable_names_exported',false,...
 'original_caller_numeric_only_finite_coefficient_vectors',true,...
 'raw_input_sha256','48e7517b8cb6cc211193c9466707b98bd484b8af349f7276c4e9960ae86f6e79',...
 'cohorts',12,'repetitions',2,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function w=v257_numeric_bisquare(u)
global V257_OBS V257_COEFF_COUNT V257_CALLBACK_COUNT;
V257_CALLBACK_COUNT=V257_CALLBACK_COUNT+1;
w=double(abs(u)<1).*(1-u.^2).^2;
current=[];found=false;
try
 meta=evalin('caller','whos');
 for j=1:numel(meta)
  m=meta(j);
  if ~strcmp(m.class,'double') || prod(m.size)~=V257_COEFF_COUNT
   continue;
  end
  candidate=evalin('caller',m.name);
  if isa(candidate,'double') && isreal(candidate) && isvector(candidate) ...
       && numel(candidate)==V257_COEFF_COUNT && all(isfinite(candidate(:)))
   current=double(candidate(:));found=true;break;
  end
 end
catch
 found=false;
end
% On postfit callback stages, the genuine caller need not have coefficient
% vectors. Only fitting-stage current beta is referenced by the run loop.
V257_OBS{end+1}=struct('ordinal',V257_CALLBACK_COUNT,...
 'w',w,'u_hex',{bits(u)},'current',current,...
 'original_numeric_coefficient_vector_found',found);
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
