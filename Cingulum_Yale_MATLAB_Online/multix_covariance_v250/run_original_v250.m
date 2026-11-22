function run_original_v250()
% V250 source-DISCLOSED original-only covariance/inference numerical probe.
% Genuine unchanged R2026b robustfit(X,y); independently evaluate public
% MATLAB triangular inverse and covariance association variants.
% No proprietary source, no internal runtime variables, no source first-blind.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.schema,'CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND'));
assert(d.seed==202611220211 && numel(d.cases)==48);
rows=struct('id',{},'rep',{},'n',{},'p',{},...
 'original_robustfit_b_hex',{},'original_scale_s_hex',{},...
 'original_covb_hex',{},'original_coeffcorr_hex',{},...
 'original_se_hex',{},'original_t_hex',{},'original_p_hex',{},...
 'original_QR_R_pivot_hex',{},'original_QR_perm_one_based',{},...
 'source_triangular_inverse_backslash_hex',{},'source_triangular_inverse_inv_hex',{},...
 'source_base_crossprod_hex',{},'covariance_candidates',{});
for rep=1:2
 for index=1:48
  c=d.cases(index);
  n=double(c.n);p=double(c.p)+1;
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,p-1);
  y=hex2num(char(c.y_hex));y=y(:);
  A=[ones(n,1),X];
  [b,stats]=robustfit(X,y);
  assert(numel(fieldnames(stats))==17);
  [Q,R,perm]=qr(A,'econ','vector'); %#ok<ASGLU>
  assert(isequal(sort(perm),1:p));
  Tback=R\eye(p);
  Tinv=inv(R);
  Cback=Tback*Tback';
  Cinv=Tinv*Tinv';
  Csource=Tback'*Tback;
  scale=stats.s;
  ss=scale*scale;
  candidate=struct();
  candidate.backslash_TT_scaled_once_hex=bits(permute_cov(Cback*ss,perm));
  candidate.backslash_TT_scaled_twice_hex=bits(permute_cov((Cback*scale)*scale,perm));
  candidate.backslash_scaled_T_times_scaled_T_hex=bits(permute_cov((Tback*scale)*(Tback*scale)',perm));
  candidate.backslash_TT_scale_then_left_hex=bits(permute_cov(ss*Cback,perm));
  candidate.backslash_TT_scale_separately_hex=bits(permute_cov(scale*(scale*Cback),perm));
  candidate.inv_TT_scaled_once_hex=bits(permute_cov(Cinv*ss,perm));
  candidate.inverse_T_transpose_T_scaled_once_hex=bits(permute_cov(Csource*ss,perm));
  candidate.normal_equations_inverse_scaled_hex=bits(inv(A'*A)*ss);
  candidate.original_R_general_inverse_TT_scaled_hex=bits(inv(stats.R)*inv(stats.R)'*ss);
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p-1,...
   'original_robustfit_b_hex',{bits(b)},...
   'original_scale_s_hex',{bits(scale)},...
   'original_covb_hex',{bits(stats.covb)},...
   'original_coeffcorr_hex',{bits(stats.coeffcorr)},...
   'original_se_hex',{bits(stats.se)},...
   'original_t_hex',{bits(stats.t)},...
   'original_p_hex',{bits(stats.p)},...
   'original_QR_R_pivot_hex',{bits(R)},...
   'original_QR_perm_one_based',perm,...
   'source_triangular_inverse_backslash_hex',{bits(Tback)},...
   'source_triangular_inverse_inv_hex',{bits(Tinv)},...
   'source_base_crossprod_hex',{bits(Cback)},...
   'covariance_candidates',candidate); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for i=1:48
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+48),'rep');
 assert(isequal(a,b),'original covariance variants not binary64 repeatable');
end
out=struct('classification','V250_SOURCE_DISCLOSED_ORIGINAL_MATLAB_MULTIX_COVARIANCE_NUMERICAL_ALTERNATIVES',...
 'run',getenv('GITHUB_RUN_ID'),'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_disclosed',true,'first_original_source_unseen_certificate',false,...
 'original_robustfit_unchanged',true,...
 'original_input_sha256','5836d8f460b64c889feda69ee69dc4792a5ff85bf120600f346171150eb2a559',...
 'cases',48,'repetitions',2,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function C=permute_cov(U,p)
n=size(U,1);
C=zeros(n,n);
C(p,p)=U;
end
function out=bits(v)
out=cellstr(num2hex(double(v(:))));
end
