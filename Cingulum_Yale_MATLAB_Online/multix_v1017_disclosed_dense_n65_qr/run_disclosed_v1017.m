function run_disclosed_v1017()
% Genuine R2026b Update 1 QR factor trace on immutable V1015 independently generated dense source-only inputs.
% Source-disclosed diagnostic. No Rust values or MATLAB numerical oracle files.
assert(exist('OCTAVE_VERSION','builtin') == 0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
assert(maxNumCompThreads == 1);
cpu = fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));

root = fileparts(mfilename('fullpath'));
source = fullfile(root,'input.json');
inputs = jsondecode(fileread(source));
assert(strcmp(inputs.classification,'V1015_N65_DENSE_PUBLIC_QR_SOURCE_ONLY'));
assert(inputs.source_only && strcmp(inputs.V12,'SEALED'));
assert(~inputs.original_MATLAB_numerical_outputs_read);
assert(~inputs.independent_Rust_outputs_read);
assert(double(inputs.seed) == 20261125101501);
assert(numel(inputs.matrices) == 32);

rows = struct('matrix_id',{},'rep',{},'n',{},'p',{},'z',{}, ...
    'unpivoted_r_row0',{},'unpivoted_r_row1',{}, ...
    'unpivoted_q_col0',{},'unpivoted_q_col1',{}, ...
    'pivoted_permutation',{},'pivoted_r_row0',{},'pivoted_r_row1',{}, ...
    'pivoted_q_col0',{},'pivoted_q_col1',{});
for rep = 1:2
 for mi = 1:numel(inputs.matrices)
  m = inputs.matrices(mi);
  n = double(m.n);
  p = double(m.p);
  assert(n == 65 && (p == 10 || p == 11));
  assert(isequal(double(m.padding(:).'),[0,1,2,7]));
  X = reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  for z = double(m.padding(:).')
   Xp = [X;zeros(z,p)];
   [Q,R] = qr(Xp,0);
   [Qp,Rp,pivot] = qr(Xp,'econ','vector');
   assert(isequal(size(R),[p,p]));
   assert(isequal(size(Rp),[p,p]));
   assert(isequal(size(Q),[n+z,p]));
   assert(isequal(size(Qp),[n+z,p]));
   assert(isequal(sort(double(pivot(:).')) , 1:p));
   rows(end+1) = struct('matrix_id',char(m.id),'rep',rep, ...
      'n',n,'p',p,'z',z, ...
      'unpivoted_r_row0',{cellstr(num2hex(double(R(1,:).')))}, ...
      'unpivoted_r_row1',{cellstr(num2hex(double(R(2,:).')))}, ...
      'unpivoted_q_col0',{cellstr(num2hex(double(Q(:,1))))}, ...
      'unpivoted_q_col1',{cellstr(num2hex(double(Q(:,2))))}, ...
      'pivoted_permutation',double(pivot(:).'), ...
      'pivoted_r_row0',{cellstr(num2hex(double(Rp(1,:).')))}, ...
      'pivoted_r_row1',{cellstr(num2hex(double(Rp(2,:).')))}, ...
      'pivoted_q_col0',{cellstr(num2hex(double(Qp(:,1))))}, ...
      'pivoted_q_col1',{cellstr(num2hex(double(Qp(:,2))))}); %#ok<AGROW>
  end
 end
end

assert(numel(rows) == 256);
for i = 1:128
 a = rmfield(rows(i),'rep');
 b = rmfield(rows(i+128),'rep');
 assert(isequal(a,b),'V1017 original MATLAB repeated public QR bits drift');
end
result = struct('classification','V1017_R2026B_SOURCE_DISCLOSED_V1015_DENSE_PUBLIC_QR_FACTORS', ...
    'V12','SEALED','source_unseen_firstblind',false,'source_only_inputs',true, ...
    'original_only_reads_Rust_values',false, ...
    'source_V1015_SHA256','2b47df9130632d8503952a08b3d2aa0e69787312b5f6d55597f0346dadea76a3', ...
    'release',version,'mkl_cbwr',getenv('MKL_CBWR'), ...
    'original_run_id',getenv('GITHUB_RUN_ID'),'repetitions',2,'rows',rows);
f = fopen(fullfile(root,'original_v1017.json'),'w');
assert(f > 0);
cleanup = onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(result));
end
