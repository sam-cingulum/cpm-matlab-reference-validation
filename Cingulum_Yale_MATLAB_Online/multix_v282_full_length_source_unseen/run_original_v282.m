function run_original_v282()
% V282 genuinely NEW first-original-blind original full-length MATLAB
% R2026b mldivide. NEVER RUN before private V283 frozen native coefficients,
% preregistered strict scorer, negative controls and SHA source custody are
% committed and pushed. Original-only: no native Rust forecasts are read.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,'CINGULUM_V282_NEW_SOURCE_UNSEEN_FULL_LENGTH_ZERO_PADDED_MLDIVIDE'));
assert(raw.seed==202611220282&&numel(raw.cases)==64);
assert(~raw.source_original_MATLAB_numeric_results_consulted);
assert(~raw.predicted_full_length_original_coefficients_disclosed_to_MATLAB_runner);
assert(strcmp(raw.first_original_blind_V252_verdict_unchanged,'FAIL'));
assert(strcmp(raw.historical_reduced_V263_first_original_blind,'PASS_216_OF_216'));
assert(strcmp(raw.comprehensive_V12,'SEALED'));
pads=double(raw.padding_counts(:).');
assert(isequal(pads,[0 1 6 7 16]));
rows=struct('id',{},'rep',{},'n',{},'p',{},'family',{},'padding_original_results',{});
for rep=1:2
 for ci=1:64
  c=raw.cases(ci);n=double(c.n);p=double(c.p);
  assert(n>=23&&n<=129&&p>=3&&p<=8);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(all(size(A)==[n p])&&numel(b)==n);
  assert(all(A(end,:)==0)&&b(end)==0);
  assert(all(isfinite(A(:)))&&all(isfinite(b)));
  assert(rank(A(1:end-1,:))==p,'Prospective original X must be full rank');
  forecast=cell(numel(pads),1);
  for ki=1:numel(pads)
   z=pads(ki);
   X=[A;zeros(z,p)];
   y=[b;zeros(z,1)];
   beta=X\y;
   assert(numel(beta)==p&&all(isfinite(beta)));
   forecast{ki}=struct('extra_terminal_zero_rows',z,...
    'source_original_full_length_backslash_b_hex',{bits(beta)});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'family',c.family,...
    'padding_original_results',{forecast}); %#ok<AGROW>
 end
end
assert(numel(rows)==128);
for i=1:64
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+64),'rep');
 assert(isequal(a,b),'Fresh source-original first-blind result not bitwise repeatable');
end
out=struct('classification',...
 'V282_GENUINE_MATHWORKS_R2026B_FIRST_ORIGINAL_BLIND_FULL_LENGTH_MLDIVIDE',...
 'source_original_first_blind',true,...
 'first_execution_expected_only_after_V283_native_forecast_frozen',true,...
 'original_source_only',true,...
 'original_numerical_forecast_from_Rust_seen_by_MATLAB',false,...
 'MathWorks_proprietary_source_exported',false,...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'raw_input_sha256','c7c3bbc0fbaff60378103dcdc8c9424fb9d05d82c92470f338632111da44945a',...
 'seed',202611220282,'cases',64,'repetitions',2,...
 'padding_counts',pads,...
 'historical_V252_first_original_blind_full17','FAIL',...
 'historical_V263_first_original_blind_reduced','PASS_216_OF_216',...
 'comprehensive_V12','SEALED',...
 'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
