function run_original_v306()
% V306 original-ONLY MathWorks R2026b UPDATE 1 first-original-blind
% full-length multi-RHS mldivide. DO NOT execute before private frozen Rust
% forecast, strict scorer and negative controls are committed and PUSHED.
% The original source reads only public synthetic X and 16-column B bits,
% NEVER native Rust coefficients. Historical FAIL/PASS contracts immutable.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,'V306_NEW_SOURCE_UNSEEN_GENUINE_MATLAB_FULL_LENGTH_MULTI_RHS_MLDIVIDE'));
assert(d.seed==202611220306&&numel(d.cases)==48);
assert(d.max_RHS_columns==16);
assert(~d.source_MATLAB_numerical_results_consulted);
assert(~d.Rust_binary64_forecast_supplied_to_original);
assert(d.first_original_blind_certificate_candidate);
assert(strcmp(d.historical_V252_first_blind_full17,'FAIL'));
assert(strcmp(d.historical_V263_first_blind_reduced,'PASS_216_OF_216'));
assert(strcmp(d.historical_V284_first_blind_full_length_single,'PASS_1770_OF_1770'));
assert(strcmp(d.universal_V12,'SEALED'));
widths=[1 2 3 4 5 6 7 8 9 12 16];padding=[0 1 7];
assert(isequal(double(d.RHS_matrix_widths(:).'),widths));
assert(isequal(double(d.padding_counts(:).'),padding));
rows=struct('id',{},'rep',{},'n',{},'p',{},'family',{},'original_padding_stages',{});
for rep=1:2
 for ci=1:48
  c=d.cases(ci);n=double(c.n);p=double(c.p);
  assert(n>=23&&n<=129&&p>=3&&p<=8);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B16=reshape(hex2num(char(c.rhs16_colmajor_hex)),n,16);
  assert(isequal(size(A),[n p])&&isequal(size(B16),[n 16]));
  assert(all(isfinite(A(:)))&&all(isfinite(B16(:))));
  assert(all(A(end,:)==0)&&all(B16(end,:)==0));
  assert(isequal(B16(:,1),B16(:,2)),'duplicate source-only RHS control missing');
  assert(rank(A(1:end-1,:))==p,'new original-only source matrix rank deficient');
  padded=cell(numel(padding),1);
  for zi=1:numel(padding)
   z=padding(zi);
   X=[A;zeros(z,p)];
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);
    B=[B16(:,1:w);zeros(z,w)];
    answer=X\B;
    assert(isequal(size(answer),[p,w])&&all(isfinite(answer(:))));
    cols=cell(w,1);
    for j=1:w
     cols{j}=bits(answer(:,j));
    end
    panels{wi}=struct('rhs_width',w,'original_full_length_backslash_columns_b_hex',{cols});
   end
   padded{zi}=struct('extra_terminal_zero_rows',z,'rhs_width_panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'family',c.family,...
    'original_padding_stages',{padded}); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for i=1:48
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+48),'rep');
 assert(isequal(a,b),'V306 first-original-blind MATLAB original must repeat bitwise');
end
out=struct(...
 'classification','V306_GENUINE_MATHWORKS_R2026B_NEW_FIRST_ORIGINAL_BLIND_FULL_MULTI_RHS',...
 'source_original_first_blind',true,...
 'original_source_only',true,...
 'original_Rust_numeric_forecast_seen',false,...
 'genuine_original_first_execution_only_after_private_native_forecast_remote_freeze',true,...
 'original_proprietary_MathWorks_source_exported',false,...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'original_public_raw_input_sha256','0afa148cee5a966cac05c3678f10c43a83bf4adc6daa519a2b9343a43736f285',...
 'cases',48,'repetitions',2,'rhs_widths',widths,'padding',padding,...
 'historical_V252_first_blind_full17','FAIL',...
 'historical_V263_first_blind_reduced','PASS_216_OF_216',...
 'historical_V284_first_blind_full_length_single','PASS_1770_OF_1770',...
 'universal_V12','SEALED','rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function out=bits(values)
out=cellstr(num2hex(double(values(:))));
end
