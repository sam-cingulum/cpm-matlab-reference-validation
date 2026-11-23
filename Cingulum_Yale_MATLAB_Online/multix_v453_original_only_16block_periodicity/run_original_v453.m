function run_original_v453()
% Genuine MATLAB R2026b Update 1, SOURCE-DISCLOSED physical-row padding dispatch.
% This is original-only evidence, NOT new original-firstblind parity.
% No Rust numbers, forecasts, previously captured original results or Octave.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
assert(isunix && isfile('/proc/cpuinfo'));
cpu=fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'), ...
    'Only preregistered AMD original CPU hosts are allowed');
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,...
 'V453_SOURCE_DISCLOSED_R2026B_ORIGINAL_ONLY_REFLECTOR_BLOCK16_PERIODICITY'));
assert(d.source_only && d.NOT_new_original_firstblind);
assert(~d.original_MATLAB_numerical_outputs_read && ~d.independent_Rust_outputs_read);
assert(strcmp(d.V12,'SEALED') && d.seed==202611230453);
assert(d.case_count==96 && d.matrix_count==8);
assert(numel(d.cases)==96 && numel(d.matrices)==8);
assert(isequal(double(d.padding(:).'),0:35));
assert(isequal(double(d.widths(:).'),[1 12 16]));
assert(strcmp(d.V449_source_input_SHA256,...
 'e2fc94a01754901a2ff9da73f6b4f479857c126e5ce71e962e66fe0b92d4c079'));
matId=string({d.matrices.id});
assert(numel(unique(matId))==8);
padvec=0:35;widths=[1 12 16];
XCache=cell(8,36);
matrixQr=struct('id',{},'n',{},'p',{},'pads',{});
for mi=1:8
 m=d.matrices(mi);n=double(m.n);p=double(m.p);
 assert(ismember(n,[48 65]) && ismember(p,[9 10 11 12]));
 A=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
 assert(all(isfinite(A(:))) && all(A(end,:)==0));
 assert(rank(A(1:end-1,:))==p);
 qrPads=cell(36,1);
 for zi=1:36
  z=padvec(zi);X=[A;zeros(z,p)];
  [~,R,P]=qr(X,'econ','vector');
  assert(isequal(double(P(:).'),1:p) && all(diag(R)~=0));
  assert(all(isfinite(R(:))));
  XCache{mi,zi}=X;
  qrPads{zi}=struct('z',z,'R_colmajor_hex',{cellstr(num2hex(double(R(:))))}, ...
                    'pivot_onebased',double(P(:).'));
 end
 matrixQr(mi)=struct('id',m.id,'n',n,'p',p,'pads',{qrPads});
end
rows=struct('id',{},'rep',{},'n',{},'p',{},'layout',{},'probe',{},'pads',{});
for rep=1:2
 for ci=1:96
  c=d.cases(ci);mi=find(matId==string(c.matrix_id));
  assert(isscalar(mi));
  n=double(d.matrices(mi).n);p=double(d.matrices(mi).p);
  assert(numel(c.b_colmajor_hex)==n);
  b=reshape(double(hex2num(char(c.b_colmajor_hex))),n,1);
  assert(all(isfinite(b)) && b(end)==0);
  assert(ismember(string(c.layout),["repeated","alternating_sign"]));
  B16=repmat(b,1,16);
  if strcmp(c.layout,'alternating_sign')
   B16(:,2:2:16)=-B16(:,2:2:16);
  end
  pads=cell(36,1);
  for zi=1:36
   z=padvec(zi);X=XCache{mi,zi};
   panels=cell(3,1);
   for wi=1:3
    w=widths(wi);Y=[B16(:,1:w);zeros(z,w)];
    beta=X\Y;
    assert(isequal(size(beta),[p,w]) && all(isfinite(beta(:))));
    cols=cell(w,1);
    for j=1:w
     cols{j}=cellstr(num2hex(double(beta(1:2,j))));
    end
    panels{wi}=struct('w',w,'original_beta_first2_colmajor_hex',{cols});
   end
   pads{zi}=struct('z',z,'panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p, ...
    'layout',c.layout,'probe',c.probe,'pads',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==192);
for i=1:96
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+96),'rep');
 assert(isequal(a,b),'Original MATLAB hidden solver not bitwise repeatable');
end
out=struct(...
 'classification','V453_GENUINE_R2026B_SOURCE_DISCLOSED_ORIGINAL_BLOCK16_PERIODICITY', ...
 'NOT_new_firstblind',true, 'V12','SEALED',...
 'source_original_only_reads_Rust_values',false,...
 'original_source_input_SHA256','15da245a8ef367890a9edd2c95545ef1709bfe2af7a707166d3c7bfcb4d47803',...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'), ...
 'matrix_count',8,'case_count',96,'repetitions',2, ...
 'padding',padvec,'widths',widths, ...
 'hidden_panel_solves_per_repetition',10368, ...
 'original_matrix_qr',matrixQr,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
