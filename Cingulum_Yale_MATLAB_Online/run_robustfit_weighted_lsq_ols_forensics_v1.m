function report=run_robustfit_weighted_lsq_ols_forensics_v1()
% Genuine original MathWorks R2026b numerical API. Independent WLS and OLS
% formulas on 24 already disclosed synthetic fits. Original robustfit stays
% unchanged. Returns only observed numeric hex and fit equality counts.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(base,'manifest.json')));
d=jsondecode(fileread(fullfile(base,'input.json')));
assert(m.samples==24 && numel(d.samples)==24 && m.source_not_run);
bname={'weighted_sqrt_backslash',...
 'weighted_lscov',...
 'weighted_normal_equations',...
 'weighted_backslash_direct_weights',...
 'weighted_lscov_normalized'};
oname={'OLS_residual_y_minus_X_OLS_beta',...
 'OLS_norm_over_sqrt_df',...
 'OLS_Q_Pythagorean_y_norm_minus_Qy_norm',...
 'OLS_Q_projector_residual_norm',...
 'OLS_sqrt_sumsq_resid_over_df',...
 'OLS_Qy_reported_projector_residual_norm',...
 'OLS_Qy_reported_pythagorean'};
tpl=struct('id','','n',0,'source_beta_hex',{{}},...
 'source_Qy_hex',{{}},'independent_Qy_hex',{{}},...
 'source_w_hex',{{}},'recomputed_w_hex',{{}},...
 'wfun_weight_exact',0,'Qy_exact',0,...
 'WLS_slope_exact',zeros(1,5),'WLS_intercept_exact',zeros(1,5),...
 'OLS_s_exact',zeros(1,7),...
 'source_ols_s_hex','','WLS_beta_hex',{{}},'OLS_s_hex',{{}},...
 'original_source_unmodified',true);
rows=repmat(tpl,1,24);
for k=1:24
 item=d.samples(k);x=double(item.x(:));y=double(item.y(:));
 n=numel(x);X=[ones(n,1),x];
 [beta,st]=robustfit(x,y);
 [Q,R,p]=qr(X,'econ','vector');
 assert(numel(st.Qy)==2 && numel(st.w)==n);
 Qy=Q'*y;
 w=st.w(:);assert(all(isfinite(w)) && all(w>=0));
 sqrtw=sqrt(w);
 WX=X.*sqrtw;Wy=y.*sqrtw;
 % Independently authored weighted least-squares mathematical formulations.
 wb1=WX\Wy;
 wb2=lscov(X,y,w);
 wb3=(X'*(w.*X))\(X'*(w.*y));
 wb4=(X.*w)\(y.*w);
 wb5=lscov(X,y,w./max(w));
 weight_betas=[wb1,wb2,wb3,wb4,wb5];
 ols_b=X\y;
 r_ols=y-X*ols_b;
 r_q=y-Q*(Q'*y);
 r_qy=y-Q*st.Qy(:);
 candidates=[sqrt(sum(r_ols.^2)/(n-2)),...
    norm(r_ols)/sqrt(n-2),...
    sqrt((sum(y.^2)-sum(Qy.^2))/(n-2)),...
    norm(r_q)/sqrt(n-2),...
    sqrt(sum(r_ols.^2))/sqrt(n-2),...
    norm(r_qy)/sqrt(n-2),...
    sqrt((sum(y.^2)-sum(st.Qy(:).^2))/(n-2))];
 % Compute independent post-fit weights using the previously exact source
 % h and MAD; no original weight values are read into candidate algorithm.
 Z=X/st.R;h=sum(Z.^2,2);
 assert(isequal(num2hex(st.h),num2hex(h)));
 residual=y-X*beta;
 corrected=residual.*(1./sqrt(1-h));
 normalized=corrected./(st.mad_s*4.685);
 wi=double(abs(normalized)<1).*(1-normalized.^2).^2;
 row=tpl;row.id=item.id;row.n=n;
 row.source_beta_hex=cellstr(num2hex(beta))';
 row.source_Qy_hex=cellstr(num2hex(st.Qy(:)))';
 row.independent_Qy_hex=cellstr(num2hex(Qy(:)))';
 row.Qy_exact=sum(strcmp(row.source_Qy_hex,row.independent_Qy_hex));
 row.source_w_hex=cellstr(num2hex(w))';
 row.recomputed_w_hex=cellstr(num2hex(wi))';
 row.wfun_weight_exact=sum(strcmp(row.source_w_hex,row.recomputed_w_hex));
 row.source_ols_s_hex=num2hex(st.ols_s);
 row.WLS_beta_hex=cell(1,numel(bname));row.OLS_s_hex=cell(1,numel(oname));
 for j=1:numel(bname)
  row.WLS_beta_hex{j}=cellstr(num2hex(weight_betas(:,j)))';
  row.WLS_slope_exact(j)=strcmp(row.WLS_beta_hex{j}{2},row.source_beta_hex{2});
  row.WLS_intercept_exact(j)=strcmp(row.WLS_beta_hex{j}{1},row.source_beta_hex{1});
 end
 for j=1:numel(oname)
  row.OLS_s_hex{j}=num2hex(candidates(j));
  row.OLS_s_exact(j)=strcmp(row.OLS_s_hex{j},row.source_ols_s_hex);
 end
 rows(k)=row;
end
wls_s=zeros(1,numel(bname));wls_i=zeros(1,numel(bname));
ols_s=zeros(1,numel(oname));
for i=1:numel(bname)
 wls_s(i)=sum(arrayfun(@(a)a.WLS_slope_exact(i),rows));
 wls_i(i)=sum(arrayfun(@(a)a.WLS_intercept_exact(i),rows));
end
for i=1:numel(oname),ols_s(i)=sum(arrayfun(@(a)a.OLS_s_exact(i),rows));end
report=struct('status','GENUINE_MATHWORKS_R2026B_ORIGINAL_WLS_OLS_SOURCE_COMPONENT_NUMERICS',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'source_original_robustfit_unmodified',true,'already_disclosed_inputs',true,...
 'source_implementation_not_extracted',true,...
 'original_input_sha256',m.input_sha256,'cases',numel(rows),...
 'WLS_methods',{bname},'OLS_scale_methods',{oname},...
 'WLS_slope_exact_totals',wls_s,'WLS_intercept_exact_totals',wls_i,...
 'OLS_scale_exact_totals',ols_s,...
 'source_Qy_exact_total',sum([rows.Qy_exact]),...
 'source_final_w_exact_total',sum([rows.wfun_weight_exact]),...
 'rows',rows);
outdir=fullfile(root,'robustfit_weighted_lsq_ols_forensics_v1');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'source_wls_ols_numeric.json'),'w');assert(fid>0);
finish=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('ORIGINAL_MATLAB_NUMERIC_WLS_BETA_CANDIDATES=%d\n',numel(rows));
for i=1:numel(bname)
 fprintf('WLS %s SLOPE=%d INTERCEPT=%d\n',bname{i},wls_s(i),wls_i(i));
end
for i=1:numel(oname),fprintf('OLS %s EXACT=%d\n',oname{i},ols_s(i));end
fprintf('SOURCE_QY_EXACT=%d SOURCE_WEIGHT_EXACT=%d\n',report.source_Qy_exact_total,report.source_final_w_exact_total);
end
