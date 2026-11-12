function run_r2026b_original_Qy_OLS_api_retro_480_v1()
% Original MathWorks R2026b Qy and ols_s numerical expression forensics.
% Original robustfit itself remains UNMODIFIED. Data already source-disclosed:
% this is explicitly retrospective, not a source-unseen parity certificate.
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
input=jsondecode(fileread(fullfile(root,'robustfit_conditional_480_v3','input.json')));
assert(numel(input.cases)==480);
method_names={'pivoted_Qtranspose_mtimes_y',...
 'pivoted_Q_col_dot_y',...
 'pivoted_sum_Qtimes_y',...
 'pivoted_Q_col_mtimes_y',...
 'pivoted_R_times_X_backslash_y',...
 'pivoted_R_times_pivotedX_backslash_y',...
 'unpivoted_Qtranspose_mtimes_y',...
 'unpivoted_sum_Qtimes_y'};
scale_names={'sqrt_sum_resid_OLS_squared_div_df',...
 'norm_OLS_residual_div_sqrt_df',...
 'sqrt_sum_resid_OLS_squared_div_sqrt_df',...
 'sqrt_norm_OLS_residual_squared_div_df',...
 'sqrt_pythagorean_y2_minus_Qy2',...
 'sqrt_pythagorean_y2_minus_reported_source_Qy2',...
 'norm_pivoted_Q_projected_residual_div_sqrt_df',...
 'norm_original_source_Qy_projected_residual_div_sqrt_df'};
qy_exact=zeros(1,numel(method_names));qy_cells=zeros(1,numel(method_names));
ols_exact=zeros(1,numel(scale_names));
rows=struct('id',{},'n',{},'pivot',{},'source_original_Qy_hex',{},'Qy_methods_hex',{},...
 'source_original_ols_s_hex',{},'ols_methods_hex',{},'original_robustfit_repeat_exact',{});
for k=1:numel(input.cases)
 c=input.cases(k);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));x=x(:);y=y(:);n=numel(x);
 assert(n==c.n && numel(y)==n);
 X=[ones(n,1),x];[Q,R,p]=qr(X,'econ','vector');
 [b,st]=robustfit(x,y);
 assert(isequal(num2hex(st.R(:)),num2hex(st.R(:))) && numel(st.Qy)==2 && isfinite(st.ols_s));
 p=p(:);assert(isequal(sort(p),[1;2]));
 remap=@(z) accumarray(p,z,[2,1]);
 qym=Q'*y;
 qyd=[dot(Q(:,1),y);dot(Q(:,2),y)];
 qys=sum(Q.*y,1)';
 qyscalar=[Q(:,1)'*y;Q(:,2)'*y];
 b_ols=X\y;
 qyr=R*b_ols(p);
 byp=X(:,p)\y;
 qyrp=R*byp;
 [Q0,~]=qr(X,0);
 qy0=Q0'*y;
 qy0s=sum(Q0.*y,1)';
 opts={remap(qym),remap(qyd),remap(qys),remap(qyscalar),...
       remap(qyr),remap(qyrp),qy0,qy0s};
 assert(numel(opts)==numel(method_names));
 target=cellstr(num2hex(st.Qy(:)));
 qy_hex=cell(1,numel(method_names));
 for j=1:numel(method_names)
  qy_hex{j}=cellstr(num2hex(opts{j}(:)))';
  qy_cells(j)=qy_cells(j)+sum(strcmp(qy_hex{j}(:),target(:)));
  qy_exact(j)=qy_exact(j)+double(all(strcmp(qy_hex{j}(:),target(:))));
 end
 initial_resid=y-X*b_ols;df=n-2;
 c1=sqrt(sum(initial_resid.^2)/df);
 c2=norm(initial_resid)/sqrt(df);
 c3=sqrt(sum(initial_resid.^2))/sqrt(df);
 c4=sqrt(norm(initial_resid)^2/df);
 c5=sqrt((sum(y.^2)-sum(qym.^2))/df);
 c6=sqrt((sum(y.^2)-sum(st.Qy(:).^2))/df);
 c7=norm(y-Q*qym)/sqrt(df);
 qy_for_pivot=st.Qy(:);qy_for_pivot=qy_for_pivot(p);
 c8=norm(y-Q*qy_for_pivot)/sqrt(df);
 scale=[c1 c2 c3 c4 c5 c6 c7 c8];
 assert(numel(scale)==numel(scale_names));
 olshex=cellstr(num2hex(scale(:)))';
 for j=1:numel(scale_names)
  ols_exact(j)=ols_exact(j)+strcmp(olshex{j},num2hex(st.ols_s));
 end
 % Additional pristine original-source repeat gate in the same session.
 [b2,st2]=robustfit(x,y);
 original_same=isequal(num2hex([b;st.Qy(:);st.ols_s;st.robust_s;st.s]),...
    num2hex([b2;st2.Qy(:);st2.ols_s;st2.robust_s;st2.s]));
 assert(original_same,'Original robustfit numerics changed on repeat');
 rec=struct();rec.id=c.id;rec.n=n;rec.pivot=p(:)';
 rec.source_original_Qy_hex=target';rec.Qy_methods_hex=qy_hex;
 rec.source_original_ols_s_hex=num2hex(st.ols_s);rec.ols_methods_hex=olshex;
 rec.original_robustfit_repeat_exact=original_same;
 rows(end+1)=rec; %#ok<AGROW>
end
assert(numel(rows)==480 && all([rows.original_robustfit_repeat_exact]));
report=struct('classification','GENUINE_ORIGINAL_MATHWORKS_R2026B_RETROSPECTIVE_Qy_OLS_SOURCE_API_DISCRIMINATION',...
 'matlab_version',version,'matlab_release',version('-release'),...
 'cpu_architecture',computer,'MKL_CBWR',getenv('MKL_CBWR'),...
 'input_schema',input.schema,'case_count',480,...
 'source_robustfit_unmodified',true,'original_source_repeats_bitwise_exact',true,...
 'source_disclosed_not_source_unseen',true,...
 'qy_methods',{method_names},'source_original_Qy_exact_case_totals',qy_exact,...
 'source_original_Qy_exact_cell_totals',qy_cells,...
 'ols_methods',{scale_names},'source_original_ols_s_exact_case_totals',ols_exact,...
 'rows',rows);
outdir=fullfile(root,'robustfit_Qy_OLS_original_api_retro_480_v1');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'original_matlab_qy_ols_methods.json'),'w');assert(fid>0);
fprintf(fid,'%s\n',jsonencode(report));fclose(fid);
for j=1:numel(method_names)
 fprintf('ORIGINAL_MATLAB_Qy_API_RETRO method=%s full=%d/480 cells=%d/960\n',method_names{j},qy_exact(j),qy_cells(j));
end
for j=1:numel(scale_names)
 fprintf('ORIGINAL_MATLAB_OLS_s_API_RETRO method=%s full=%d/480\n',scale_names{j},ols_exact(j));
end
end
