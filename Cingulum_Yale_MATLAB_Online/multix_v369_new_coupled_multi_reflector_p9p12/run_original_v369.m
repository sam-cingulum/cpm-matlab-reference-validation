function run_original_v369()
% V369 newly source-UNSEEN original MATLAB R2026b Update 1.
% Full coupled predictor QR and 182784 exact backslash coefficients.
% STRICT NO EXECUTION before the new private independently compiled
% Rust V370 firstblind forecast, strict V370 scorer and SHA preoracle
% are committed PUSHED and remote SHA verified. Never read Rust outputs.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,'V369_GENUINELY_NEW_SOURCE_ORIGINAL_UNSEEN_P9P12_COUPLED_MULTI_REFLECTOR_MLDIVIDE'));
assert(d.new_first_original_blind_candidate && ~d.original_MATLAB_numerical_results_seen_before_freeze);
assert(~d.original_only_source_can_read_Rust_forecast);
assert(d.seed==202611230369 && d.case_count==32 && numel(d.cases)==32);
assert(d.new_source_original_unseen_coefficients==182784);
assert(strcmp(d.historical_V340_firstblind,'IMMUTABLE_FAIL_63871_OF_182784'));
assert(strcmp(d.V366_firstblind,'PASS_365568_OF_365568'));
assert(strcmp(d.V12,'SEALED'));
widths=1:16;padding=[0 1 7 16];
assert(isequal(double(d.widths(:).'),widths));
assert(isequal(double(d.paddings(:).'),padding));
rows=struct('id',{},'rep',{},'n',{},'p',{},'family',{},'original_padding_stages',{});
for rep=1:2
 for ci=1:32
  c=d.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[19 31 48 65]) && ismember(p,[9 10 11 12]) && n>p);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B16=reshape(hex2num(char(c.rhs16_colmajor_hex)),n,16);
  assert(all(isfinite(A(:)))&&all(isfinite(B16(:))));
  assert(all(A(end,:)==0)&&all(B16(end,:)==0));
  assert(isequal(B16(:,1),B16(:,2))&&isequal(B16(:,9),B16(:,10)));
  assert(rank(A(1:end-1,:))==p,'NEW original coupled A rank deficient');
  pads=cell(numel(padding),1);
  for zi=1:numel(padding)
   z=padding(zi);X=[A;zeros(z,p)];
   [~,R,perm]=qr(X,'econ','vector');
   assert(numel(perm)==p && isequal(sort(double(perm(:).')),1:p));
   assert(all(diag(R)~=0) && all(isfinite(R(:))));
   assert(any(any(triu(R,1)~=0)),'coupled source is accidentally diagonal R');
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);B=[B16(:,1:w);zeros(z,w)];
    sol=X\B;
    assert(isequal(size(sol),[p w]) && all(isfinite(sol(:))));
    cols=cell(w,1);
    for j=1:w
     cols{j}=cellstr(num2hex(double(sol(:,j))));
    end
    panels{wi}=struct('rhs_width',w,'original_full_length_backslash_columns_b_hex',{cols});
   end
   pads{zi}=struct('extra_terminal_zero_rows',z,...
     'original_public_qr_pivot_one_based',double(perm(:).'),...
     'original_public_qr_R_column_major_bits',{cellstr(num2hex(double(R(:))))},...
     'rhs_width_panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'family',c.family,...
   'original_padding_stages',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==64);
for i=1:32
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+32),'rep');
 assert(isequal(a,b),'NEW original Matlab full outputs not repeatable');
end
out=struct(...
 'classification','V369_GENUINE_R2026B_NEW_FIRST_ORIGINAL_BLIND_COUPLED_MULTI_REFLECTOR_P9P12',...
 'source_original_first_blind',true,...
 'source_original_code_reads_Rust_values',false,...
 'genuine_original_first_execution_only_after_private_native_forecast_remote_freeze',true,...
 'original_public_input_sha256','ed37acd5118b127caa4a46b3b7082c8a4d3007d6c208668902b91a6a1838f7ef',...
 'run_id',getenv('GITHUB_RUN_ID'),'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'case_count',32,'repetitions',2,'widths',widths,'paddings',padding,...
 'historical_V340_firstblind','IMMUTABLE_FAIL_63871_OF_182784',...
 'V366_firstblind','PASS_365568_OF_365568',...
 'V12','SEALED','rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
