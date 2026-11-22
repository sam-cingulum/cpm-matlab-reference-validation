function run_original_v364()
% V364 MathWorks R2026b Update 1 genuinely NEW ORIGINAL-FIRST-BLIND.
% 365,568 binary64 full-length multi-RHS mldivide coefficients.
%
% DO NOT execute until independent compiled pure-Rust V331 numeric forecast
% and strict post-original V332 scorer, preoracle negative controls, and SHA
% custody are committed and PUSHED on the private cingulum-cpm main branch.
% Read ONLY the new public synthetic X/B. NEVER import Rust coefficients.
% Historical V308 full original first-blind FAIL cannot be retrofitted.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,...
 'V364_NEW_GENUINE_FIRST_ORIGINAL_BLIND_P9P12_ONE_REFLECTOR_NUMERICAL_CHALLENGE'));
assert(d.seed==202611230364 && d.case_count==64 && numel(d.cases)==64);
assert(d.new_prospective_first_original_blind);
assert(~d.source_original_MATLAB_numerical_data_consulted);
assert(~d.source_original_reads_Rust_forecast);
assert(strcmp(d.V340_original_first_blind,'IMMUTABLE_FAIL_63871_OF_182784'));
assert(strcmp(d.V332_original_first_blind,'PASS_261120_OF_261120'));
assert(strcmp(d.V336_original_first_blind,'PASS_261120_OF_261120'));
assert(strcmp(d.V363_source_disclosed,'EXACT_182784_OF_182784'));
assert(strcmp(d.V12,'SEALED'));
widths=1:16;
padding=[0 1 7 16];
assert(isequal(double(d.widths(:).'),widths));
assert(isequal(double(d.padding(:).'),padding));
rows=struct('id',{},'rep',{},'n',{},'p',{},'mode',{},'original_padding_stages',{});
for rep=1:2
 for ci=1:64
  c=d.cases(ci);
  n=double(c.n);p=double(c.p);
  assert(ismember(n,[19 31 48 65]) && ismember(p,[9 10 11 12]) && n>p);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B16=reshape(hex2num(char(c.b16_colmajor_hex)),n,16);
  assert(isequal(size(A),[n p])&&isequal(size(B16),[n 16]));
  assert(all(isfinite(A(:)))&&all(isfinite(B16(:))));
  assert(all(A(end,:)==0)&&all(B16(end,:)==0));
  assert(isequal(B16(:,1),B16(:,2)));
  assert(isequal(B16(:,9),B16(:,10)));
  assert(rank(A(1:end-1,:))==p,'source-original NEW matrix is rank deficient');
  pads=cell(numel(padding),1);
  for zi=1:numel(padding)
   z=padding(zi);
   X=[A;zeros(z,p)];
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);
    B=[B16(:,1:w);zeros(z,w)];
    answer=X\B;
    assert(isequal(size(answer),[p w])&&all(isfinite(answer(:))));
    cols=cell(w,1);
    for j=1:w
     cols{j}=cellstr(num2hex(double(answer(:,j))));
    end
    panels{wi}=struct('rhs_width',w,...
      'original_full_length_backslash_columns_b_hex',{cols});
   end
   pads{zi}=struct('extra_terminal_zero_rows',z,...
     'rhs_width_panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'mode',c.mode,...
    'original_padding_stages',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==128);
for i=1:64
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+64),'rep');
 assert(isequal(a,b),'source original R2026b V364 two repetitions not bitwise identical');
end
output=struct(...
 'classification','V364_GENUINE_MATHWORKS_R2026B_NEW_FIRST_ORIGINAL_BLIND_P9P12_DIAGONAL_R',...
 'source_original_first_blind',true,...
 'V363_source_disclosed','EXACT_182784_OF_182784',...
 'original_source_only',true,...
 'original_Rust_numeric_forecast_seen',false,...
 'genuine_original_first_execution_only_after_private_native_forecast_remote_freeze',true,...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'original_public_raw_input_sha256','736f4cb24717b918adb40002f7972b73827409d7e25e82cf2fd56445ebc45fb5',...
 'cases',64,'repetitions',2,'rhs_widths',widths,'padding',padding,...
 'historical_V308_first_blind','IMMUTABLE_FAIL_54741_OF_57816',...
 'historical_V332_first_blind_wide','PASS_261120_OF_261120',...
 'historical_V336_first_blind_adversarial','PASS_261120_OF_261120',...
 'historical_V340_first_blind','IMMUTABLE_FAIL_63871_OF_182784',...
 'historical_V284_first_blind_full_length_single','PASS_1770_OF_1770',...
 'universal_V12','SEALED','rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(output));
end
