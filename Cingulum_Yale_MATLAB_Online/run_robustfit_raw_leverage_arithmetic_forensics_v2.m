function report=run_robustfit_raw_leverage_arithmetic_forensics_v2()
% Genuine MATLAB R2026b numerical API experiment, 24 already disclosed fits.
% Test mathematical leverage calculations against original robustfit st.h.
% All formulations independently authored; proprietary source never read.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(base,'manifest.json')));
data=jsondecode(fileread(fullfile(base,'input.json')));
assert(m.samples==24 && numel(data.samples)==24 && m.source_not_run);
names={'pivot_Q_row_square_sum',...
 'nonpivot_Q_row_square_sum',...
 'original_X_divide_original_R',...
 'pivot_X_divide_pivot_R',...
 'pivot_Q_row_dot_self',...
 'pivot_Q_projection_diag',...
 'nonpivot_Q_projection_diag',...
 'X_normal_equations_projection_diag',...
 'X_pinv_projection_diag',...
 'centered_mean_analytic_leverage',...
 'original_X_divide_original_R_manual_dot',...
 'pivot_X_divide_pivot_R_manual_dot',...
 'X_normal_equations_inverse_dot'};
rows=repmat(struct('id','','n',0,'source_h_hex',{{}},...
 'original_R_rowmajor_hex',{{}},'original_R_numeric',zeros(2,2),...
 'exact_by_method',zeros(1,13),'max_error_by_method',zeros(1,13),...
 'hex_by_method',{{}},'method_names',{{}}),1,24);
for k=1:24
 q=data.samples(k);x=double(q.x(:));y=double(q.y(:));n=numel(x);
 X=[ones(n,1),x];
 [~,st]=robustfit(x,y);
 [Q,R]=qr(X,0);
 [Qp,Rp,p]=qr(X,'econ','vector');
 Rp_orig=Rp;
 if isequal(double(p(:)'),[2 1])
  Rp_orig=Rp([2 1],[2 1]);
 end
 % Must preserve original pivot reported R bits as distinct gate.
 assert(isequal(num2hex(Rp_orig),num2hex(st.R)));
 Z=X/Rp_orig;
 Zp=X(:,p)/Rp;
 qsum=sum(Qp.^2,2);
 qnosum=sum(Q.^2,2);
 qdot=Qp(:,1).*Qp(:,1)+Qp(:,2).*Qp(:,2);
 hq=diag(Qp*Qp');
 hn=diag(Q*Q');
 gram=X'*X;
 ht=diag(X*(gram\X'));
 hpinv=diag(X*pinv(X));
 mx=mean(x);
 ss=sum((x-mx).^2);
 hcenter=1/n+((x-mx).^2)/ss;
 zdot=Z(:,1).*Z(:,1)+Z(:,2).*Z(:,2);
 zpdot=Zp(:,1).*Zp(:,1)+Zp(:,2).*Zp(:,2);
 invnormal=inv(gram);
 ht2=sum((X*invnormal).*X,2);
 candidates=[qsum,qnosum,sum(Z.^2,2),sum(Zp.^2,2),qdot,...
    hq,hn,ht,hpinv,hcenter,zdot,zpdot,ht2];
 assert(isequal(size(candidates),[n,numel(names)]));
 rec=rows(k);
 rec.id=q.id;rec.n=n;rec.source_h_hex=cellstr(num2hex(st.h(:)))';
 rec.original_R_numeric=st.R;
 rec.original_R_rowmajor_hex={num2hex(st.R(1,1)),num2hex(st.R(1,2)),...
      num2hex(st.R(2,1)),num2hex(st.R(2,2))};
 rec.exact_by_method=zeros(1,numel(names));
 rec.max_error_by_method=zeros(1,numel(names));
 rec.hex_by_method=cell(1,numel(names));
 rec.method_names=names;
 for j=1:numel(names)
  ref=cellstr(num2hex(candidates(:,j)));
  rec.hex_by_method{j}=ref';
  rec.exact_by_method(j)=sum(strcmp(ref,rec.source_h_hex(:)));
  rec.max_error_by_method(j)=max(abs(candidates(:,j)-st.h(:)));
 end
 rows(k)=rec;
end
totals=zeros(1,numel(names));
maxima=zeros(1,numel(names));
for j=1:numel(names)
 totals(j)=sum(arrayfun(@(a)a.exact_by_method(j),rows));
 maxima(j)=max(arrayfun(@(a)a.max_error_by_method(j),rows));
end
report=struct('status','GENUINE_MATHWORKS_R2026B_ORIGINAL_LEVERAGE_RAW_X_R_WITHIN_RUN',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'original_source_unmodified',true,'input_source_previously_disclosed',true,...
 'input_sha256',m.input_sha256,'sample_count',24,...
 'element_count',sum([rows.n]),'methods',{names},...
 'source_h_exact_totals',totals,'source_h_max_abs_errors',maxima,...
 'records',rows);
outdir=fullfile(root,'robustfit_raw_leverage_forensics_v2');
if ~exist(outdir,'dir'),mkdir(outdir);end
fd=fopen(fullfile(outdir,'genuine_source_leverage_candidates.json'),'w');assert(fd>0);
finish=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
fprintf('GENUINE_R2026B_ORIGINAL_H_TOTAL=%d\n',report.element_count);
for j=1:numel(names)
 fprintf('%s: EXACT %d/%d MAX_ABS %.17g\n',names{j},totals(j),report.element_count,maxima(j));
end
end
