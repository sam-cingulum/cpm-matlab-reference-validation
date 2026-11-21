function run_original_v218()
% SOURCE-DISCLOSED, post-V211 original MATLAB R2026b multi-X diagnostics.
% Captures independent native-stage reference Q, pivot, raw row right divide
% and row norms to isolate the p>=3 robustfit leverage and Qy bits.
% This is NOT new original-blind certification and MUST NOT relabel V211.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND'));
assert(raw.seed==202611220211 && numel(raw.cases)==48);
rows=struct('id',{},'n',{},'p',{},'rep',{},'Q_hex',{},'QR_R_hex',{}, ...
 'QR_E_hex',{},'stats_R_hex',{},'QR_R_reordered_hex',{},'stats_Qy_hex',{}, ...
 'QTy_coefficient_hex',{},'X_over_source_R_hex',{}, ...
 'h_QR_Q_hex',{},'h_X_over_R_hex',{},'stats_h_hex',{});
for rep=1:2
 for i=1:48
  c=raw.cases(i);n=double(c.n);p=double(c.p);
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,p);
  y=hex2num(char(c.y_hex));y=y(:);
  assert(isequal(cellstr(num2hex(X(:))),cellstr(char(c.x_colmajor_hex))));
  assert(isequal(cellstr(num2hex(y)),cellstr(char(c.y_hex))));
  A=[ones(n,1),X];
  [Q,R,E]=qr(A,0);
  [~,stats]=robustfit(X,y);
  assert(numel(stats.h)==n && isequal(size(Q),[n,p+1]));
  % The public qr(A,0) API can return a permutation VECTOR on this
  % original release; expand it to the genuine binary permutation matrix.
  if isvector(E)
    assert(numel(E)==p+1);
    positions=E(:);
    P=zeros(p+1,p+1);
    for j=1:p+1,P(positions(j),j)=1;end
    E=P;
  end
  assert(isequal(size(E),[p+1,p+1]),'invalid original QR permutation');
  assert(isequal(size(stats.R),[p+1,p+1]));
  row=struct();
  row.id=c.id;row.n=n;row.p=p;row.rep=rep;
  row.Q_hex=cellstr(num2hex(Q(:)));
  row.QR_R_hex=cellstr(num2hex(R(:)));
  row.QR_E_hex=cellstr(num2hex(E(:)));
  row.stats_R_hex=cellstr(num2hex(stats.R(:)));
  reordered=E*R*E';
  row.QR_R_reordered_hex=cellstr(num2hex(reordered(:)));
  row.stats_Qy_hex=cellstr(num2hex(stats.Qy(:)));
  qy_reordered=E*(Q'*y);
  row.QTy_coefficient_hex=cellstr(num2hex(qy_reordered(:)));
  XR=A/stats.R;
  row.X_over_source_R_hex=cellstr(num2hex(XR(:)));
  row.h_QR_Q_hex=cellstr(num2hex(sum(Q.^2,2)));
  row.h_X_over_R_hex=cellstr(num2hex(sum(XR.^2,2)));
  row.stats_h_hex=cellstr(num2hex(stats.h(:)));
  rows(end+1)=row; %#ok<AGROW>
 end
end
for i=1:48
 a=rows(i);b=rows(i+48);a=rmfield(a,'rep');b=rmfield(b,'rep');
 assert(isequal(a,b),'genuine MATLAB QR diagnostic repetitions differed');
end
out=struct('classification','V218_SOURCE_DISCLOSED_R2026B_MULTIX_QR_LEVERAGE_QY_ORIGINAL_ONLY', ...
 'source_disclosed',true,'new_original_blind',false, ...
 'release',version,'computer',computer,'mkl_cbwr',getenv('MKL_CBWR'), ...
 'max_num_comp_threads',maxNumCompThreads,'run',getenv('GITHUB_RUN_ID'), ...
 'input_sha256','5836d8f460b64c889feda69ee69dc4792a5ff85bf120600f346171150eb2a559', ...
 'case_count',48,'repetitions',2,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end