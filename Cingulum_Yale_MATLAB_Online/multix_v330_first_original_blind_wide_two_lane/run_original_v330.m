function run_original_v330()
% V330 MathWorks R2026b Update 1 genuinely NEW ORIGINAL-FIRST-BLIND.
% 261,120 binary64 full-length multi-RHS mldivide coefficients.
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
 'V330_NEW_GENUINE_ORIGINAL_FIRST_BLIND_FULL_LENGTH_WIDE_TWO_LANE_MULTI_RHS'));
assert(d.seed==202611220330 && d.cohorts==64 && numel(d.cases)==64);
assert(d.max_RHS_columns==16);
assert(d.first_original_blind_certificate_candidate);
assert(~d.source_original_MATLAB_numerical_results_seen);
assert(~d.original_mathworks_sees_native_forecast);
assert(strcmp(d.previous_first_blind_V308,'IMMUTABLE_FAIL_54741_OF_57816'));
assert(strcmp(d.previous_first_blind_V284_single,'PASS_1770_OF_1770'));
assert(strcmp(d.V252_full17,'FAIL'));
assert(strcmp(d.V263_reduced,'PASS_216_OF_216'));
assert(strcmp(d.V12,'SEALED'));
widths=1:16;
padding=[0 1 7 16];
assert(isequal(double(d.RHS_matrix_widths(:).'),widths));
assert(isequal(double(d.padding_counts(:).'),padding));
rows=struct('id',{},'rep',{},'n',{},'p',{},'family',{},'original_padding_stages',{});
for rep=1:2
 for ci=1:64
  c=d.cases(ci);
  n=double(c.n);p=double(c.p);
  assert(n>=19 && n<=137 && ismember(p,[7 8]) && n>p);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B16=reshape(hex2num(char(c.rhs16_colmajor_hex)),n,16);
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
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'family',c.family,...
    'original_padding_stages',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==128);
for i=1:64
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+64),'rep');
 assert(isequal(a,b),'source original R2026b V330 two repetitions not bitwise identical');
end
output=struct(...
 'classification','V330_GENUINE_MATHWORKS_R2026B_NEW_FIRST_ORIGINAL_BLIND_WIDE_TWO_LANE',...
 'source_original_first_blind',true,...
 'original_source_only',true,...
 'original_Rust_numeric_forecast_seen',false,...
 'genuine_original_first_execution_only_after_private_native_forecast_remote_freeze',true,...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'original_public_raw_input_sha256','8baa36c0d3938326011fab566c572754d8791ae8a72987ec36fd2aa2754044b2',...
 'cases',64,'repetitions',2,'rhs_widths',widths,'padding',padding,...
 'historical_V308_first_blind','IMMUTABLE_FAIL_54741_OF_57816',...
 'historical_V252_first_blind_full17','FAIL',...
 'historical_V263_first_blind_reduced','PASS_216_OF_216',...
 'historical_V284_first_blind_full_length_single','PASS_1770_OF_1770',...
 'universal_V12','SEALED','rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(output));
end
