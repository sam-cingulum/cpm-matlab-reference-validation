function report=run_robustfit_original_qr_api_raw_x_forensics_v1()
% Research-only original MathWorks R2026b numeric API semantics: does the
% original robustfit QR state equal qr([ones x],0) and/or pivoted qr?
% The exact MATLAB original source input and source are unchanged.
% No original MathWorks proprietary source implementation is extracted.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
folder=fullfile(root,'robustfit_source_fd_prospective_v1');
m=jsondecode(fileread(fullfile(folder,'manifest.json')));
d=jsondecode(fileread(fullfile(folder,'input.json')));
assert(m.samples==24 && numel(d.samples)==24 && m.source_not_run);
tpl=struct('id','','n',0,'pivot',[0 0],...
 'source_R_hex',{{}},'pivot_reconstructed_R_hex',{{}},'nonpivot_R_hex',{{}},...
 'source_h_hex',{{}},'pivot_Q_h_hex',{{}},'nonpivot_Q_h_hex',{{}},...
 'source_R_pivot_exact_elements',0,...
 'source_R_nonpivot_exact_elements',0,...
 'source_h_pivot_exact_elements',0,...
 'source_h_nonpivot_exact_elements',0);
rows=repmat(tpl,1,24);
for k=1:24
 c=d.samples(k);x=double(c.x(:));y=double(c.y(:));n=numel(x);
 X=[ones(n,1),x];
 [~,st]=robustfit(x,y);
 [Q,R]=qr(X,0);
 [Qp,Rp,p]=qr(X,0,'vector');
 assert(isequal(sort(double(p(:)')),1:2));
 % Numerical orthogonal/triangular factor reported by robustfit uses a
 % coefficient-order form of a possible pivoted Householder factor.
 Rp_original_order=Rp;
 if isequal(double(p(:)'),[2 1])
  Rp_original_order=Rp([2 1],[2 1]);
 end
 h_pivot=sum(Qp.^2,2);
 h_nonpivot=sum(Q.^2,2);
 sr=cellstr(num2hex(st.R(:)));
 pr=cellstr(num2hex(Rp_original_order(:)));
 nr=cellstr(num2hex(R(:)));
 sh=cellstr(num2hex(st.h(:)));
 ph=cellstr(num2hex(h_pivot(:)));
 nh=cellstr(num2hex(h_nonpivot(:)));
 row=tpl;
 row.id=c.id;row.n=n;row.pivot=double(p(:)');
 row.source_R_hex=sr';row.pivot_reconstructed_R_hex=pr';
 row.nonpivot_R_hex=nr';row.source_h_hex=sh';
 row.pivot_Q_h_hex=ph';row.nonpivot_Q_h_hex=nh';
 row.source_R_pivot_exact_elements=sum(strcmp(sr,pr));
 row.source_R_nonpivot_exact_elements=sum(strcmp(sr,nr));
 row.source_h_pivot_exact_elements=sum(strcmp(sh,ph));
 row.source_h_nonpivot_exact_elements=sum(strcmp(sh,nh));
 rows(k)=row;
end
report=struct('status','GENUINE_MATHWORKS_R2026B_ORIGINAL_QR_RAW_X_API_FORENSICS',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'original_robustfit_unmodified',true,...
 'original_inputs_previously_disclosed',true,...
 'source_code_not_extracted',true,...
 'input_sha256',m.input_sha256,'cases',24,'records',rows,...
 'source_R_pivot_exact_total',sum([rows.source_R_pivot_exact_elements]),...
 'source_R_nonpivot_exact_total',sum([rows.source_R_nonpivot_exact_elements]),...
 'source_h_pivot_exact_total',sum([rows.source_h_pivot_exact_elements]),...
 'source_h_nonpivot_exact_total',sum([rows.source_h_nonpivot_exact_elements]));
outdir=fullfile(root,'robustfit_original_qr_raw_x_forensics_v1');
if ~exist(outdir,'dir'),mkdir(outdir);end
fid=fopen(fullfile(outdir,'original_source_qr_api_stage.json'),'w');assert(fid>0);
finish=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
fprintf('REAL_MATHWORKS_QR_VS_ORIGINAL_ROBUSTFIT_R_PIVOT_BITS %d/96\n',report.source_R_pivot_exact_total);
fprintf('REAL_MATHWORKS_QR_VS_ORIGINAL_ROBUSTFIT_H_PIVOT_BITS %d\n',report.source_h_pivot_exact_total);
end
