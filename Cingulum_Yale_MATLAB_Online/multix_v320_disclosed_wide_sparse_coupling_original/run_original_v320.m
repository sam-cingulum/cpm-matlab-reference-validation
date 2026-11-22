function run_original_v320()
% V320 genuine MathWorks R2026b source-DISCLOSED controlled p7/p8.
% One active Householder reflector, all later pivot columns are orthogonal
% basis vectors. Design is structurally diagonal-R. This does not change the
% independent original-first-blind V308 54741/57816 immutable FAIL.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,...
 'V320_SOURCE_DISCLOSED_WIDE_P7P8_SPARSE_OFFDIAGONAL_COUPLING_ORIGINAL'));
assert(d.source_disclosed_after_V308);
assert(~d.source_original_MATLAB_numerical_data_consulted);
assert(d.seed==202611220320 && d.case_count==64 && numel(d.cases)==64);
assert(strcmp(d.original_first_blind_V308,'IMMUTABLE_FAIL_54741_OF_57816'));
assert(strcmp(d.V284_solo_original_first_blind,'PASS_1770_OF_1770'));
assert(strcmp(d.V12,'SEALED'));
widths=[1 2 3 4 5 6 7 8 9 12 16];
paddings=[0 1 7];
assert(isequal(double(d.widths(:).'),widths));
assert(isequal(double(d.padding(:).'),paddings));
rows=struct('id',{},'rep',{},'p',{},'n',{},'coupling_pattern',{},'original_padded_backslash',{});
for rep=1:2
 for ci=1:64
  c=d.cases(ci);p=double(c.p);n=double(c.n);
  assert(ismember(p,[7 8]) && n>p);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B16=reshape(hex2num(char(c.b16_colmajor_hex)),n,16);
  assert(isequal(size(A),[n p]) && isequal(size(B16),[n 16]));
  assert(all(isfinite(A(:))) && all(isfinite(B16(:))));
  assert(all(A(end,:)==0) && all(B16(end,:)==0));
  assert(isequal(B16(:,1),B16(:,2)),'frozen duplicate RHS values changed');
  assert(rank(A(1:end-1,:))==p,'structural controlled source matrix rank deficiency');
  assert(all(A(2:p,1)==0));
  for j=2:p
   ix=setdiff((1:n)',[1,j]);
   assert(all(A(ix,j)==0),'basis source matrix not sparse');
   assert(A(j,j)>0);
  end
  pads=cell(3,1);
  for zi=1:3
   z=paddings(zi);
   X=[A;zeros(z,p)];
   [~,QR,P]=qr(X,'econ','vector');
   assert(isequal(sort(P),1:p));
   assert(all(diag(QR)~=0) && all(isfinite(QR(:))));
   stages=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);
    B=[B16(:,1:w);zeros(z,w)];
    beta=X\B;
    assert(isequal(size(beta),[p w])&&all(isfinite(beta(:))));
    cols=cell(w,1);
    for col=1:w
     cols{col}=cellstr(num2hex(double(beta(:,col))));
    end
    stages{wi}=struct('rhs_width',w,'source_original_full_mldivide_col_hex',{cols});
   end
   pads{zi}=struct('terminal_zero_padding',z,...
     'public_QR_R_colmajor_hex',{cellstr(num2hex(double(QR(:))))},...
     'public_QR_permutation_onebased',P,'rhs_width_panels',{stages});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'p',p,'n',n,'coupling_pattern',c.coupling_pattern,...
    'original_padded_backslash',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==128);
for i=1:64
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+64),'rep');
 assert(isequal(a,b),'source-disclosed original repeat not bitwise identical');
end
output=struct('classification',...
 'V320_GENUINE_R2026B_SOURCE_DISCLOSED_WIDE_SPARSE_OFFDIAGONAL_COUPLING',...
 'source_disclosed_after_V308',true,...
 'source_original_run',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_public_X_B_sha256','1fd1aaf6d6af68d70ff9a03289f46282fc7edf5190a9d22b3c59c3342442db91',...
 'original_first_blind_V308','IMMUTABLE_FAIL_54741_OF_57816',...
 'V284_original_first_blind_solo','PASS_1770_OF_1770',...
 'V12','SEALED',...
 'case_count',64,'original_repetitions',2,'padding',paddings,...
 'rhs_widths',widths,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(output));
end
