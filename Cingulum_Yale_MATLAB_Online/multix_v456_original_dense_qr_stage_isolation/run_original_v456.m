function run_original_v456()
% V456 genuine MATLAB R2026b dense hidden-solver vs explicit QR-stage audit.
% SOURCE-DISCLOSED and original-only, never accesses independent Rust outputs.
% For these DENSE matrices, qr(S,B) two-input is documented for SPARSE S,
% and is intentionally NOT used as a false oracle for the dense hidden solve.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
cpu=fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));
root=fileparts(mfilename('fullpath'));
source=fullfile(root,'..','multix_v449_original_only_zero_padding_stride_switch','input.json');
s=jsondecode(fileread(source));
assert(strcmp(s.classification,'V449_SOURCE_DISCLOSED_R2026B_ORIGINAL_ONLY_PADDED_ROW_STRIDE_DISPATCH'));
assert(s.source_only && s.NOT_new_original_firstblind);
assert(~s.original_MATLAB_numerical_outputs_read && ~s.independent_Rust_outputs_read);
assert(strcmp(s.V12,'SEALED') && s.case_count==96 && s.matrix_count==8);
assert(numel(s.cases)==96 && numel(s.matrices)==8);
assert(isequal(double(s.widths(:).'),[1 2 11 12 13 16]));
assert(isequal(double(s.padding(:).'),0:16));
matIds=string({s.matrices.id});
assert(numel(unique(matIds))==8);
widths=[1 12 16];
qrInfo=struct('id',{},'n',{},'p',{},'pads',{});
padsByN48=[0 2 3 7];padsByN65=[0 1 2 7];
for mi=1:8
 m=s.matrices(mi);n=double(m.n);p=double(m.p);
 assert(ismember(n,[48 65]) && ismember(p,[9 10 11 12]));
 X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
 assert(all(isfinite(X(:))) && all(X(end,:)==0) && rank(X(1:end-1,:))==p);
 zvec=padsByN48;
 if n==65;zvec=padsByN65;end
 qrPads=cell(numel(zvec),1);
 for zi=1:numel(zvec)
  z=zvec(zi);
  Xp=[X;zeros(z,p)];
  [~,R,P]=qr(Xp,'econ','vector');
  assert(isequal(double(P(:).'),1:p));
  assert(isequal(size(R),[p p]) && all(isfinite(R(:))) && all(diag(R)~=0));
  qrPads{zi}=struct('z',z,'R_colmajor_hex',{cellstr(num2hex(double(R(:))))}, ...
    'pivot_onebased',double(P(:).'));
 end
 qrInfo(mi)=struct('id',m.id,'n',n,'p',p,'pads',{qrPads});
end
rows=struct('id',{},'rep',{},'n',{},'p',{},'layout',{},'probe',{},'pads',{});
for rep=1:2
 for ci=1:96
  c=s.cases(ci);
  mi=find(matIds==string(c.matrix_id));
  assert(isscalar(mi));
  m=s.matrices(mi);n=double(m.n);p=double(m.p);
  X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  b=reshape(hex2num(char(c.b_colmajor_hex)),n,1);
  assert(all(isfinite(b)) && b(end)==0);
  Y16=repmat(b,1,16);
  assert(ismember(string(c.layout),["repeated","alternating_sign"]));
  if strcmp(c.layout,'alternating_sign')
   Y16(:,2:2:16)=-Y16(:,2:2:16);
  end
  zvec=padsByN48;
  if n==65;zvec=padsByN65;end
  pads=cell(numel(zvec),1);
  for zi=1:numel(zvec)
   z=zvec(zi);
   Xp=[X;zeros(z,p)];
   [Q,R,P]=qr(Xp,'econ','vector');
   assert(isequal(double(P(:).'),1:p));
   assert(isequal(R(:),hex2num(char(qrInfo(mi).pads{zi}.R_colmajor_hex))));
   D=decomposition(Xp,'qr');
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);
    Y=[Y16(:,1:w);zeros(z,w)];
    hidden=Xp\Y;
    projected=Q'*Y;
    explicit=R\projected;
    opts=struct('UT',true);
    upper=linsolve(R,projected,opts);
    decomposed=D\Y;
    backprojected=R*hidden;
    assert(all(isfinite(hidden(:))) && all(isfinite(projected(:))) ...
      && all(isfinite(explicit(:))) && all(isfinite(upper(:))) ...
      && all(isfinite(decomposed(:))) && all(isfinite(backprojected(:))));
    assert(isequal(size(hidden),[p w]) && isequal(size(projected),[p w]) ...
      && isequal(size(explicit),[p w]) && isequal(size(upper),[p w]) ...
      && isequal(size(decomposed),[p w]) && isequal(size(backprojected),[p w]));
    cols=cell(w,1);
    for j=1:w
     cols{j}=struct( ...
      'hidden_X_backslash_Y_hex',{cellstr(num2hex(double(hidden(:,j))))}, ...
      'public_Qtrans_Y_hex',{cellstr(num2hex(double(projected(:,j))))}, ...
      'explicit_R_backslash_QtransY_hex',{cellstr(num2hex(double(explicit(:,j))))}, ...
      'explicit_linsolve_upper_QtransY_hex',{cellstr(num2hex(double(upper(:,j))))}, ...
      'explicit_decomposition_qr_backslash_Y_hex',{cellstr(num2hex(double(decomposed(:,j))))}, ...
      'backprojected_R_times_hidden_hex',{cellstr(num2hex(double(backprojected(:,j))))});
    end
    panels{wi}=struct('w',w,'columns',{cols});
   end
   pads{zi}=struct('z',z,'panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,...
   'layout',c.layout,'probe',c.probe,'pads',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==192);
for i=1:96
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+96),'rep');
 assert(isequal(a,b),'original MATLAB stage audit not binary64 deterministic');
end
out=struct( ...
 'classification','V456_R2026B_SOURCE_DISCLOSED_GENUINE_DENSE_HIDDEN_VS_EXPLICIT_QR_STAGE_ISOLATION', ...
 'NOT_new_firstblind',true,'V12','SEALED',...
 'source_original_only_reads_Rust_values',false,...
 'source_V449_input_SHA256','e2fc94a01754901a2ff9da73f6b4f479857c126e5ce71e962e66fe0b92d4c079',...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'matrix_count',8,'case_count',96,'repetitions',2,...
 'widths',widths,'padding_n48',padsByN48,'padding_n65',padsByN65,...
 'panel_solves_per_repetition',96*4*numel(widths),...
 'original_matrix_qr',qrInfo,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
