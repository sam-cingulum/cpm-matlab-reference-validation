function run_original_v918()
% Genuine original-only n65 cancellation RHS holdout for frozen V918 sources.
% No Rust predictions or prior original numerical outputs enter this program.
assert(exist('OCTAVE_VERSION','builtin') == 0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
assert(maxNumCompThreads == 1);
cpu = fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));

root = fileparts(mfilename('fullpath'));
s = jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(s.classification,'V918_N65_CANCELLATION_RHS_SOURCE_ONLY'));
assert(s.source_only && strcmp(s.V12,'SEALED'));
assert(~s.original_MATLAB_numerical_outputs_read && ~s.independent_Rust_outputs_read);
assert(strcmp(s.parent_V916_source_sha256, ...
    '3491a80422f606ea4edf28f770f8e58526701558855067912a1d89a1dc43399c'));
assert(numel(s.matrices) == 16 && numel(s.cases) == 448);
widths = [1,2,11,12,13,23,24,25];
assert(isequal(double(s.widths(:).'),widths));
layouts = ["repeated","signed_power2"];

rows = struct('id',{},'rep',{},'n',{},'p',{},'z',{},'probes',{});
for rep = 1:2
 for mi = 1:numel(s.matrices)
  m = s.matrices(mi);
  identifier = char(m.id);
  n = double(m.n);
  p = double(m.p);
  assert(n == 65 && (p == 10 || p == 11));
  assert(isequal(double(m.padding(:).'),[0,1,2,7]));
  matrixCases = find(strcmp({s.cases.matrix_id},identifier));
  assert(numel(matrixCases) == 28);
  X = reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  for z = double(m.padding(:).')
   Xp = [X;zeros(z,p)];
   D = decomposition(Xp,'qr');
   probes = cell(28,1);
   for pi = 1:28
    probe = s.cases(matrixCases(pi));
    b = reshape(hex2num(char(probe.b_colmajor_hex)),n,1);
    br = [b;zeros(z,1)];
    layoutRows = cell(2,1);
    for li = 1:2
     layout = layouts(li);
     Y = repmat(br,1,25);
     if layout == "signed_power2"
      for j = 1:25
       scale = pow2(1,mod(j-1,5)-2);
       if mod(j,2) == 0
        scale = -scale;
       end
       Y(:,j) = br * scale;
      end
     end
     panels = cell(numel(widths),1);
     for wi = 1:numel(widths)
      w = widths(wi);
      Z = Y(:,1:w);
      hidden = Xp\Z;
      cached = D\Z;
      assert(isequal(size(hidden),[p,w]));
      assert(isequal(size(cached),[p,w]));
      columns = cell(w,1);
      for j = 1:w
       columns{j} = struct('column',j, ...
        'hidden_first2_hex',{cellstr(num2hex(double(hidden(1:2,j))))}, ...
        'cached_first2_hex',{cellstr(num2hex(double(cached(1:2,j))))});
      end
      panels{wi} = struct('w',w,'columns',{columns});
     end
     layoutRows{li} = struct('layout',char(layout),'panels',{panels});
    end
    probes{pi} = struct('case_id',char(probe.id), ...
        'family',char(probe.family),'layouts',{layoutRows});
   end
   rows(end+1) = struct('id',identifier,'rep',rep, ...
      'n',n,'p',p,'z',z,'probes',{probes}); %#ok<AGROW>
  end
 end
end
assert(numel(rows) == 128);
for i = 1:64
 first = rmfield(rows(i),'rep');
 second = rmfield(rows(i+64),'rep');
 assert(isequal(first,second), ...
     'V918 independent genuine original MATLAB repetitions differ');
end

out = struct( ...
 'classification','V918_ORIGINAL_MATLAB_R2026B_N65_CANCELLATION_FIRSTBLIND', ...
 'V12','SEALED','source_unseen_original_firstblind',true, ...
 'original_source_reads_Rust_values',false, ...
 'input_SHA256','3e3462e23ed1172b32c06067ae74d1ca0f807b1d0fd7edcff15326c9c0f11a34', ...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'repetitions',2, ...
 'widths',widths,'rows',rows);
file = fopen(fullfile(root,'original_v918.json'),'w');
assert(file > 0);
cleanup = onCleanup(@()fclose(file));
fprintf(file,'%s\n',jsonencode(out));
end
