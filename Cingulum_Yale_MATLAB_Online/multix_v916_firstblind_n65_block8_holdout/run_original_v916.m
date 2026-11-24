function run_original_v916()
% Prospective V916 original-only n65 block8 candidate holdout.
% Numerical policy was derived retrospectively from historical V910 data.
% This source reads inputs only, never Rust forecasts or original outputs.
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
assert(strcmp(s.classification,'V916_N65_CROSS_HOLDOUT_SOURCE_ONLY'));
assert(double(s.seed) == 2026112491607);
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
 assert(isequal(a,b),'V916 genuine original MATLAB repetitions differ');
end
out = struct('classification','V916_ORIGINAL_MATLAB_R2026B_N65_BLOCK8_HOLDOUT_FIRSTBLIND', ...
 'V12','SEALED','source_unseen_original_firstblind',true, ...
 'original_source_reads_Rust_values',false, ...
 'input_SHA256','3491a80422f606ea4edf28f770f8e58526701558855067912a1d89a1dc43399c', ...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'repetitions',2, ...
 'widths',widths,'rows',rows);
file = fopen(fullfile(root,'original_v916.json'),'w');
assert(file > 0);
cleanup = onCleanup(@()fclose(file));
fprintf(file,'%s\n',jsonencode(out));
end
