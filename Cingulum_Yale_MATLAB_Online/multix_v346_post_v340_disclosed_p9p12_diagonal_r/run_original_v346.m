function run_original_v346()
% V346 genuine MathWorks R2026b source-DISCLOSED controlled p9/p10/p11/p12.
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
 'V346_POST_V340_DISCLOSED_P9P12_DIAGONAL_R_SINGLE_ACTIVE_REFLECTOR_ORIGINAL'));
assert(d.source_disclosed_after_V340);
assert(~d.source_original_MATLAB_numerical_data_consulted);
assert(d.seed==202611230346 && d.case_count==32 && numel(d.cases)==32);
assert(strcmp(d.original_first_blind_V308,'IMMUTABLE_FAIL_54741_OF_57816'));
assert(strcmp(d.V340_original_first_blind,'IMMUTABLE_FAIL_63871_OF_182784'));
assert(strcmp(d.V332_original_first_blind,'PASS_261120_OF_261120'));
assert(strcmp(d.V336_original_first_blind,'PASS_261120_OF_261120'));
assert(strcmp(d.V284_solo_original_first_blind,'PASS_1770_OF_1770'));
assert(strcmp(d.V12,'SEALED'));
widths=1:16;
paddings=[0 1 7 16];
assert(isequal(double(d.widths(:).'),widths));
assert(isequal(double(d.padding(:).'),paddings));
rows=struct('id',{},'rep',{},'p',{},'n',{},'mode',{},'original_padded_backslash',{});
for rep=1:2
 for ci=1:32
  c=d.cases(ci);p=double(c.p);n=double(c.n);
  assert(ismember(p,[9 10 11 12]) && n>p);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B16=reshape(hex2num(char(c.b16_colmajor_hex)),n,16);
  assert(isequal(size(A),[n p]) && isequal(size(B16),[n 16]));
  assert(all(isfinite(A(:))) && all(isfinite(B16(:))));
  assert(all(A(end,:)==0) && all(B16(end,:)==0));
  assert(isequal(B16(:,1),B16(:,2)),'frozen duplicate RHS values changed');
  assert(rank(A(1:end-1,:))==p,'structural controlled source matrix rank deficiency');
  assert(all(A(2:p,1)==0));
  for j=2:p
   ix=setdiff((1:n)',j);
   assert(all(A(ix,j)==0),'basis source matrix not sparse');
   assert(A(j,j)>0);
  end
  pads=cell(4,1);
  for zi=1:4
   z=paddings(zi);
   X=[A;zeros(z,p)];
   [~,QR,P]=qr(X,'econ','vector');
   assert(isequal(sort(P),1:p));
   assert(all(diag(QR)~=0) && all(isfinite(QR(:))));
   assert(isequal(P,1:p),'public QR pivot identity violated');
   assert(all(all(triu(QR,1)==0)),'public QR factor must be exactly diagonal');
   public_QtB_2col=Q'*[B16(:,1:2);zeros(z,2)];
   assert(all(isfinite(public_QtB_2col(:))));
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
     'public_QR_permutation_onebased',P,...
     'public_QtB_two_col_colmajor_hex',{cellstr(num2hex(double(public_QtB_2col(:))))},...
     'rhs_width_panels',{stages});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'p',p,'n',n,'mode',c.mode,...
    'original_padded_backslash',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==64);
for i=1:32
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+32),'rep');
 assert(isequal(a,b),'source-disclosed original repeat not bitwise identical');
end
output=struct('classification',...
 'V346_GENUINE_R2026B_POST_V340_DISCLOSED_P9P12_DIAGONAL_R_SINGLE_ACTIVE_REFLECTOR',...
 'source_disclosed_after_V340',true,...
 'V340_first_original_blind','IMMUTABLE_FAIL_63871_OF_182784',...
 'V332_first_original_blind','PASS_261120_OF_261120',...
 'V336_first_original_blind','PASS_261120_OF_261120',...
 'source_original_run',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_public_X_B_sha256','75560b79e18c770ee24c6676abfe0de3c2f1460d2a4c30940deac075508b4abc',...
 'original_first_blind_V308','IMMUTABLE_FAIL_54741_OF_57816',...
 'V284_original_first_blind_solo','PASS_1770_OF_1770',...
 'V12','SEALED',...
 'case_count',32,'original_repetitions',2,'padding',paddings,...
 'rhs_widths',widths,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(output));
end
