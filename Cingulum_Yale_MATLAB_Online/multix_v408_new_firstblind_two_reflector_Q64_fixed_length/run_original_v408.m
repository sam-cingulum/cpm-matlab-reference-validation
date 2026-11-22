function run_original_v408()
% V408 wholly new source-original-UNSEEN two-reflector PUBLIC Q/R acceptance.
% Strict prerequisite: private independently compiled Rust V409 forecast
% and SHA-scored negative-control V410 frozen, committed PUSHED, remotely
% verified BEFORE invoking this original-only genuine MathWorks MATLAB.
% Never reads ANY Rust values or substitutes Octave for original MATLAB.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,'V408_GENUINELY_NEW_FIRST_ORIGINAL_BLIND_TWO_REFLECTOR_Q_CROSS_AMD_64'));
assert(d.new_source_original_unseen_candidate);
assert(~d.original_MATLAB_numerical_outputs_seen_before_frozen_native);
assert(~d.original_only_source_can_read_Rust_numerical_predictions);
assert(d.preoracle_private_Rust_forecast_plus_7_negative_controls_required);
assert(d.seed==202611230408 && d.case_count==64 && numel(d.cases)==64);
assert(isequal(double(d.p_values(:).'),[9 10 11 12]));
assert(isequal(double(d.n_values(:).'),[48 65]));
assert(isequal(double(d.zero_paddings(:).'),[0 1 7 16]));
assert(d.new_original_Q_first_two_column_bits==32000);
assert(strcmp(d.historical_V400,'IMMUTABLE_FAIL_31336_OF_32000_Q'));
assert(strcmp(d.historical_V407,'SOURCE_DISCLOSED_ONLY_PASS_32000_OF_32000_Q'));
assert(strcmp(d.historical_V371,'IMMUTABLE_FAIL_133582_OF_182784'));
assert(strcmp(d.historical_V366,'PASS_365568_OF_365568'));
assert(strcmp(d.V12,'SEALED'));
rows=struct('id',{},'rep',{},'n',{},'p',{},'pads',{});
total_bits=0;
for rep=1:2
 for ci=1:64
  c=d.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[48 65])&&ismember(p,[9 10 11 12])&&n>p);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  assert(all(isfinite(A(:))) && all(A(end,:)==0));
  assert(rank(A(1:end-1,:))==p,'new source full rank');
  pads=cell(4,1);
  for zi=1:4
   z=double(d.zero_paddings(zi));X=[A;zeros(z,p)];
   [Q,R,P]=qr(X,'econ','vector');
   assert(isequal(P,1:p),'new original pivot identity required');
   assert(all(diag(R)~=0) && R(1,2)~=0 && all(isfinite(R(:))));
   assert(isequal(size(Q),[n+z p]));
   q2=double(Q(:,1:2));
   assert(all(isfinite(q2(:))));
   total_bits=total_bits+numel(q2);
   pads{zi}=struct('z',z,...
    'original_public_Q_first2_colmajor_hex',{cellstr(num2hex(q2(:)))},...
    'original_public_Q_diag_first2_hex',{cellstr(num2hex([Q(1,1);Q(2,2)]))},...
    'original_public_R_colmajor_hex',{cellstr(num2hex(double(R(:))))},...
    'original_public_pivot_onebased',double(P(:).'));
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'pads',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==128);
assert(total_bits==64000);
for i=1:64
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+64),'rep');
 assert(isequal(a,b),'genuine original Q/R duplicate execution NOT bitwise stable');
end
out=struct(...
 'classification','V408_GENUINE_R2026B_NEW_FIRST_ORIGINAL_BLIND_64_TWO_REFLECTOR_PUBLIC_Q_AND_R',...
 'source_original_first_blind',true,...
 'original_only_MATLAB_reads_independent_Rust_values',false,...
 'private_native_forecast_remote_frozen_before_original_execution',true,...
 'original_public_input_sha256','84c4d3d4d9130a71687b37eec8a0251fec095a8bdc4be24e91b8e30f62f1a9a6',...
 'original_run_id',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),...
 'case_count',64,'repetitions',2,'padding',[0 1 7 16],...
 'original_Q_first2_bits_per_repetition',32000,...
 'original_Q_first2_bits_both_repetitions',total_bits,...
 'historical_V400','IMMUTABLE_FAIL_31336_OF_32000_Q',...
 'historical_V407','SOURCE_DISCLOSED_ONLY_PASS_32000_OF_32000_Q',...
 'historical_V371','IMMUTABLE_FAIL_133582_OF_182784',...
 'historical_V366','PASS_365568_OF_365568',...
 'prior_V397_source_disclosed','PASS_4000_OF_4000_NOT_FIRSTBLIND',...
 'V12','SEALED','rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
