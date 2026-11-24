function run_original_v719()
% Independent original MATLAB R2026b Update 1 V719 n65 hidden solver test.
% This program reads only SHA-frozen new X/B source, never Rust forecasts.
assert(exist('OCTAVE_VERSION','builtin') == 0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
assert(maxNumCompThreads == 1);
cpu = fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));
root = fileparts(mfilename('fullpath'));
s = jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(s.classification,'V719_N65_CROSS_NUMERIC_SOURCE_ONLY_FIRSTBLIND'));
assert(double(s.seed) == 2026112471901);
assert(s.source_only && strcmp(s.V12,'SEALED'));
assert(~s.original_MATLAB_numerical_outputs_read && ~s.independent_Rust_outputs_read);
assert(numel(s.matrices) == 16 && numel(s.cases) == 80);
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
  X = reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  for z = double(m.padding(:).')
   Xp = [X;zeros(z,p)];
   D = decomposition(Xp,'qr');
   probes = cell(5,1);
   for probe = 0:4
    case_id = sprintf('%s_probe_%02d',identifier,probe);
    ci = find(string({s.cases.id}) == string(case_id));
    assert(isscalar(ci));
    b = reshape(hex2num(char(s.cases(ci).b_colmajor_hex)),n,1);
    br = [b;zeros(z,1)];
    layoutRows = cell(2,1);
    for li = 1:2
     layout = layouts(li);
     Y = repmat(br,1,25);
     if layout == "signed_power2"
      for j = 1:25
       scale = pow2(1,mod(j-1,5)-2);
       if mod(j,2) == 0;scale = -scale;end
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
    probes{probe+1} = struct('case_id',case_id,'layouts',{layoutRows});
   end
   rows(end+1) = struct('id',identifier,'rep',rep, ...
       'n',n,'p',p,'z',z,'probes',{probes}); %#ok<AGROW>
  end
 end
end
assert(numel(rows) == 128);
for i = 1:64
 a = rmfield(rows(i),'rep');
 b = rmfield(rows(i+64),'rep');
 assert(isequal(a,b),'V719 genuine original MATLAB repetitions differ');
end
out = struct('classification','V719_ORIGINAL_MATLAB_R2026B_N65_NUMERIC_FIRSTBLIND', ...
 'V12','SEALED','source_unseen_original_firstblind',true, ...
 'original_source_reads_Rust_values',false, ...
 'input_SHA256','a243dfb6f6bd7193d157a7bab6af4f53a268c227373012a1f89a08fbe011a811', ...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'repetitions',2, ...
 'widths',widths,'rows',rows);
file = fopen(fullfile(root,'original_v719.json'),'w');
assert(file > 0);
cleanup = onCleanup(@()fclose(file));
fprintf(file,'%s\n',jsonencode(out));
end
