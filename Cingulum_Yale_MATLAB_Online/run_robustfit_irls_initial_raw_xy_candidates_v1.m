function report=run_robustfit_irls_initial_raw_xy_candidates_v1()
% Genuine R2026b original robustfit with independently authored callback.
% Retrospective numerical identification of FIRST IRLS callback from raw x/y.
% No proprietary source text/code is inspected or exported.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
base=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(base,'manifest.json')));
dat=jsondecode(fileread(fullfile(base,'input.json')));
assert(m.samples==24 && numel(dat.samples)==24 && m.source_not_run);
global CINGULUM_ORIGINAL_IRLS_INITIAL_U;
names={'X_backslash_y',...
 'pivot_R_backslash_pivot_Qy',...
 'original_R_backslash_original_st_Qy',...
 'pivot_R_backslash_original_st_Qy',...
 'original_R_backslash_unpermuted_pivot_Qy',...
 'normal_equations',...
 'nonpivot_R_backslash_nonpivot_Qy',...
 'original_R_backslash_pivot_Qy'};
Rnames={'y_minus_Xtimes_beta',...
 'y_minus_Qp_times_Qptrans_y',...
 'y_minus_Qp_times_source_Qy',...
 'y_minus_Qnonpivot_times_Qnonpivottrans_y',...
 'y_minus_Qp_times_source_Qy_permuted'};
tpl=struct('id','','n',0,'initial_source_callback_u_hex',{{}},...
 'raw_first_u_exact',zeros(1,8),...
 'raw_first_mad_hex',{{}},...
 'raw_first_beta_hex',{{}},...
 'raw_first_residual_within_beta_group_exact',zeros(1,8),...
 'projection_residual_first_u_exact',zeros(1,5),...
 'projection_first_u_hex',{{}},...
 'original_beta_hex',{{}},...
 'original_R_hex',{{}},...
 'original_Qy_hex',{{}},...
 'source_callback_total',0,...
 'callback_first_u_max_abs_errors',zeros(1,8),...
 'source_implementation_unmodified',true);
records=repmat(tpl,1,24);
for i=1:24
 q=dat.samples(i);x=double(q.x(:));y=double(q.y(:));n=numel(x);
 X=[ones(n,1),x];
 [b0,st]=robustfit(x,y);
 [Qp,Rp,p]=qr(X,'econ','vector');
 [Q,R]=qr(X,0);
 Rorig=Rp;
 if isequal(double(p(:)'),[2 1]),Rorig=Rp([2 1],[2 1]);end
 assert(isequal(num2hex(st.R),num2hex(Rorig)));
 h=sum((X/Rorig).^2,2);
 assert(isequal(num2hex(h),num2hex(st.h)));
 invsqrt=1./sqrt(1-h);
 Qy=Qp'*y;
 stQy=st.Qy(:);
 w=cell(1,8);
 w{1}=X\y;
 tmp=Rp\Qy;
 bp=zeros(2,1);bp(p)=tmp;w{2}=bp;
 w{3}=Rorig\stQy;
 tmp=Rp\stQy;bp=zeros(2,1);bp(p)=tmp;w{4}=bp;
 qo=zeros(2,1);qo(p)=Qy;w{5}=Rorig\qo;
 w{6}=(X'*X)\(X'*y);
 [QN,RN]=qr(X,0);w{7}=RN\(QN'*y);
 w{8}=Rorig\Qy;
 CINGULUM_ORIGINAL_IRLS_INITIAL_U={};
 [bc,statscb]=robustfit(x,y,@capture_bisquare_first_u,4.685);
 C=CINGULUM_ORIGINAL_IRLS_INITIAL_U;
 assert(numel(C)>2 && all(strcmp(cellstr(num2hex(b0)),cellstr(num2hex(bc)))));
 source=C{1}(:);
 refh=cellstr(num2hex(source));
 rec=tpl;rec.id=q.id;rec.n=n;rec.source_callback_total=numel(C);
 rec.initial_source_callback_u_hex=refh';
 rec.original_beta_hex=cellstr(num2hex(b0))';
 rec.original_R_hex=cellstr(num2hex(st.R(:)))';
 rec.original_Qy_hex=cellstr(num2hex(st.Qy(:)))';
 rec.raw_first_mad_hex=cell(1,8);
 rec.raw_first_beta_hex=cell(1,8);
 for j=1:8
  bj=w{j};
  rr=y-X*bj;
  corrected=rr.*invsqrt;
  sorted=sort(abs(corrected));
  mad=median(sorted(2:end))/0.6745;
  if mad==0 || ~isfinite(mad),continue;end
  u=corrected./(mad*4.685);
  rec.raw_first_u_exact(j)=sum(strcmp(cellstr(num2hex(u)),refh));
  rec.raw_first_mad_hex{j}=num2hex(mad);
  rec.raw_first_beta_hex{j}=cellstr(num2hex(bj))';
  rec.callback_first_u_max_abs_errors(j)=max(abs(u-source));
  rec.raw_first_residual_within_beta_group_exact(j)=sum(strcmp(cellstr(num2hex(u)),refh));
 end
 projector=cell(1,5);
 projector{1}=y-X*w{1};
 projector{2}=y-Qp*(Qp'*y);
 projector{3}=y-Qp*stQy;
 projector{4}=y-Q*(Q'*y);
 tmp=stQy;
 if isequal(double(p(:)'),[2 1]),tmp=stQy([2 1]);end
 projector{5}=y-Qp*tmp;
 rec.projection_first_u_hex=cell(1,5);
 for j=1:5
  rr=projector{j};
  sorted=sort(abs(rr.*invsqrt));
  mad=median(sorted(2:end))/0.6745;
  u=(rr.*invsqrt)./(mad*4.685);
  rec.projection_residual_first_u_exact(j)=sum(strcmp(cellstr(num2hex(u)),refh));
  rec.projection_first_u_hex{j}=cellstr(num2hex(u))';
 end
 records(i)=rec;
 CINGULUM_ORIGINAL_IRLS_INITIAL_U={};
end
rawsum=zeros(1,numel(names));projsum=zeros(1,numel(Rnames));
for i=1:numel(names),rawsum(i)=sum(arrayfun(@(r)r.raw_first_u_exact(i),records));end
for i=1:numel(Rnames),projsum(i)=sum(arrayfun(@(r)r.projection_residual_first_u_exact(i),records));end
report=struct('status','GENUINE_MATHWORKS_R2026B_ORIGINAL_FIRST_IRLS_CALLBACK_RAW_X_Y_NUMERIC_FORENSICS',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'original_robustfit_unmodified',true,...
 'source_inputs_previously_disclosed',true,...
 'private_implementation_not_extracted',true,...
 'original_input_sha256',m.input_sha256,...
 'cases',24,'callback_elements',sum([records.n]),...
 'candidate_betas',{names},'first_u_exact_by_beta',rawsum,...
 'candidate_projection_residuals',{Rnames},...
 'first_u_exact_by_projection_residual',projsum,...
 'records',records);
out=fullfile(root,'robustfit_irls_initial_raw_xy_candidates_v1');
if ~exist(out,'dir'),mkdir(out);end
fid=fopen(fullfile(out,'original_first_irls_u_forensics.json'),'w');assert(fid>0);
closefile=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('ORIGINAL_MATHWORKS_FIRST_U_NUMERIC_CANDIDATES=%d\n',24);
for i=1:numel(names),fprintf('%s: %d/%d\n',names{i},rawsum(i),report.callback_elements);end
for i=1:numel(Rnames),fprintf('%s: %d/%d\n',Rnames{i},projsum(i),report.callback_elements);end
end

function weights=capture_bisquare_first_u(u)
global CINGULUM_ORIGINAL_IRLS_INITIAL_U;
CINGULUM_ORIGINAL_IRLS_INITIAL_U{end+1}=double(u(:));
weights=double(abs(u)<1).*(1-u.^2).^2;
end
