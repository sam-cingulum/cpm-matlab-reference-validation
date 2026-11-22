function run_original_v263()
% V263 prospectively frozen NEW unseen genuine original MATLAB R2026b
% terminal-zero QR/mldivide scope. DO NOT EXECUTE until private source-free
% Rust 216-coefficient predictions + strict scorer are remotely committed.
% Original source has no Rust forecast and invokes public original \ only.
% V252 original robustfit first-blind FAIL remains irrevocably intact.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,...
 'CINGULUM_V263_PROSPECTIVE_TERMINAL_ZERO_REDUCED_ROW_MLDIVIDE'));
assert(raw.seed==202611220263 && numel(raw.cases)==48);
assert(~raw.source_original_MATLAB_numeric_results_consulted);
assert(strcmp(raw.first_original_blind_V252_verdict_unchanged,'FAIL'));
rows=struct('id',{},'n',{},'p',{},'rep',{},...
 'source_reduced_last_zero_row_b_hex',{},...
 'source_original_full_length_backslash_b_hex',{},...
 'source_terminal_row_zero',{},...
 'source_reduced_full_rank',{});
for rep=1:2
 for index=1:48
  c=raw.cases(index);n=double(c.n);p=double(c.p);
  assert(ismember(n,[35 36 43 44 47 48 61 62 71 72 87 88]));
  assert(ismember(p,[3 4 5 6]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(numel(b)==n && size(A,2)==p && size(A,1)==n);
  assert(all(A(end,:)==0) && b(end)==0);
  assert(all(isfinite(A(:))) && all(isfinite(b)));
  assert(rank(A(1:end-1,:))==p,'Original reduced matrix must be full rank');
  reduced=A(1:end-1,:)\b(1:end-1);
  full=A\b;
  assert(numel(reduced)==p && numel(full)==p);
  assert(all(isfinite(reduced)) && all(isfinite(full)));
  rows(end+1)=struct('id',c.id,'n',n,'p',p,'rep',rep,...
   'source_reduced_last_zero_row_b_hex',{bits(reduced)},...
   'source_original_full_length_backslash_b_hex',{bits(full)},...
   'source_terminal_row_zero',true,...
   'source_reduced_full_rank',true); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for j=1:48
 a=rmfield(rows(j),'rep');b=rmfield(rows(j+48),'rep');
 assert(isequal(a,b),'genuine first original must repeat bitwise');
end
out=struct(...
 'classification','V263_GENUINE_SOURCE_UNSEEN_R2026B_ORIGINAL_REDUCED_TERMINAL_ZERO_MLDIVIDE',...
 'original_only',true,'source_original_run',getenv('GITHUB_RUN_ID'),...
 'raw_input_sha256','01f935d0b92f89f14589d4e6d35fb99d96bbea746a808b7eb4771a4461e66526',...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'first_original_blind_V252_verdict_unchanged','FAIL',...
 'new_reduced_row_first_source_unseen_certificate_candidate',true,...
 'new_full_length_mldivide_general_certificate',false,...
 'original_MathWorks_proprietary_source_exported',false,...
 'seed',202611220263,'cases',48,'repetitions',2,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
