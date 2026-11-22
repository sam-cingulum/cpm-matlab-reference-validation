function run_original_v265()
% V265 SOURCE-DISCLOSED research after original V263 source-UNSEEN PASS.
% Derive original full-length MATLAB R2026b mldivide terminal-zero row count
% numeric dispatch: 48 previously disclosed V263 real matrices, no Rust
% or predicted MATLAB result provided to original.
% V252 original first-blind FAIL and V263 restricted PASS immutable.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,'CINGULUM_V263_PROSPECTIVE_TERMINAL_ZERO_REDUCED_ROW_MLDIVIDE'));
assert(raw.seed==202611220263 && numel(raw.cases)==48);
assert(strcmp(raw.first_original_blind_V252_verdict_unchanged,'FAIL'));
assert(~raw.source_original_MATLAB_numeric_results_consulted);
ks=[0 1 2 3 4 5 7 8 9 11 12 15 16];
rows=struct('id',{},'rep',{},'n',{},'p',{},...
 'source_reduced_original_b_hex',{},'source_full_b_hex',{},...
 'source_zero_first_b_hex',{},'source_zero_mid_b_hex',{},...
 'source_padding_sweep',{});
for rep=1:2
 for ci=1:48
  c=raw.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[35 36 43 44 47 48 61 62 71 72 87 88]));
  assert(ismember(p,[3 4 5 6]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(size(A,1)==n && size(A,2)==p && numel(b)==n);
  assert(all(A(end,:)==0) && b(end)==0 && all(isfinite(A(:))) && all(isfinite(b)));
  reduced=A(1:end-1,:)\b(1:end-1);
  full=A\b;
  Afirst=[A(end,:);A(1:end-1,:)];bfirst=[b(end);b(1:end-1)];
  first=Afirst\bfirst;
  m=floor(n/2);
  Amiddle=[A(1:m,:);A(end,:);A(m+1:end-1,:)];
  bmiddle=[b(1:m);b(end);b(m+1:end-1)];
  middle=Amiddle\bmiddle;
  sweeps=cell(numel(ks),1);
  for ki=1:numel(ks)
   z=ks(ki);
   Az=[A;zeros(z,p)];
   bz=[b;zeros(z,1)];
   ansz=Az\bz;
   assert(isequal(size(ansz),[p 1]) && all(isfinite(ansz)));
   sweeps{ki}=struct('extra_terminal_zero_rows',z,'total_row_count',n+z,...
    'source_original_full_length_backslash_b_hex',{bits(ansz)});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,...
   'source_reduced_original_b_hex',{bits(reduced)},...
   'source_full_b_hex',{bits(full)},...
   'source_zero_first_b_hex',{bits(first)},...
   'source_zero_mid_b_hex',{bits(middle)},...
   'source_padding_sweep',{sweeps}); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for i=1:48
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+48),'rep');
 assert(isequal(a,b),'V265 source-original padding geometry must repeat bitwise');
end
out=struct('classification','V265_GENUINE_MATHWORKS_R2026B_POST_V263_SOURCE_DISCLOSED_ZERO_ROW_PADDING_SWEEP',...
 'source_disclosed',true,'new_first_original_blind_certification',false,...
 'previous_V263_reduced_row_first_original_blind_certificate','PASS_216_OF_216',...
 'historical_V252_original_first_blind_verdict','FAIL',...
 'original_MathWorks_proprietary_source_exported',false,...
 'original_runtime_private_caller_names_exported',false,...
 'source_original_run',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),'seed',202611220263,...
 'raw_input_sha256','01f935d0b92f89f14589d4e6d35fb99d96bbea746a808b7eb4771a4461e66526',...
 'cases',48,'repetitions',2,'extra_zero_rows_tested',ks,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
