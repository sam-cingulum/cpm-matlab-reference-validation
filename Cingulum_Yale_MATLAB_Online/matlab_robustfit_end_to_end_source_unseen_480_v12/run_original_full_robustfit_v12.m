function run_original_full_robustfit_v12()
% ORIGINAL GENUINE MATHWORKS R2026b full `[b,stats]` runner.
% This runner is preauthored for the NEXT V12 480-case unseen challenge.
% DO NOT execute until the raw V12 and independent compiled Rust full-structure
% forecasts are publicly SHA-pinned and pushed in the original chronology.
% Neither the original source nor its proprietary numerical kernels are changed.
assert(exist('OCTAVE_VERSION','builtin')==0,'Octave is not the original oracle');
assert(strcmp(version('-release'),'2026b'),'MATLAB release incompatible');
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'),'Original vendor CBWR unsupported');
maxNumCompThreads(1);
assert(maxNumCompThreads==1,'Original vendor threads unsupported');
root=fileparts(mfilename('fullpath'));
assert(exist(fullfile(root,'input.json'),'file')==2,'No V12 raw challenge frozen');
assert(exist(fullfile(root,'PREORACLE_V12_LOCK.json'),'file')==2,'No frozen independent Rust forecast manifest');
raw=jsondecode(fileread(fullfile(root,'input.json')));
lock=jsondecode(fileread(fullfile(root,'PREORACLE_V12_LOCK.json')));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_RAW_XY_FULL_ROBUSTFIT_480_V12_SOURCE_UNSEEN'));
assert(strcmp(lock.schema,'CINGULUM_R2026B_V12_PREORACLE_LOCK_SHA256_V1'));
assert(strcmp(lock.freeze_state,'FROZEN_PUBLISHED_BEFORE_MATLAB_ORIGINAL'));
assert(lock.forecast_complete_struct_has_17_stats_fields && lock.rust_input_raw_xy_only);
assert(numel(raw.cases)==480);
expected_lengths=[9 11 15 17 23 25];
fieldlist={'ols_s','robust_s','mad_s','s','resid','rstud','se',...
 'covb','coeffcorr','t','p','w','Qy','R','dfe','h','Rtol'};
% Explicit original output schema: 17 source fields plus independent b.
records=struct('id',{},'n',{},'b',{},'stats',{});
for rep=1:2
 for i=1:480
  c=raw.cases(i);
  n=double(c.n);
  assert(ismember(n,expected_lengths) && numel(c.x_hex)==n && numel(c.y_hex)==n);
  x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
  assert(all(isfinite(x)) && all(isfinite(y)));
  assert(isequal(cellstr(num2hex(x)),cellstr(char(c.x_hex))));
  assert(isequal(cellstr(num2hex(y)),cellstr(char(c.y_hex))));
  [b,st]=robustfit(x(:),y(:)); % UNMODIFIED original MathWorks R2026b.
  names=fieldnames(st);
  assert(isequal(names(:),fieldlist(:)),...
    sprintf('Original R2026b stats fields changed at case %d',i));
  assert(numel(b)==2 && numel(st.covb)==4 && numel(st.coeffcorr)==4);
  values=struct();
  for j=1:numel(names)
   name=names{j};values.(name)=pack_original_binary64(st.(name));
  end
  row=struct();row.id=c.id;row.n=n;
  row.b=pack_original_binary64(b);
  row.stats=struct();row.stats.fieldnames=names;row.stats.values=values;
  records(end+1)=row; %#ok<AGROW>
 end
 fprintf('ORIGINAL R2026b V12 entire [b,stats] pass %d/2, 480 cases complete\n',rep);
end
report=struct();
report.schema='CINGULUM_MATHWORKS_R2026B_COMPLETE_ROBUSTFIT_STATS_17_AND_B_HEX_V1';
report.classification='ORIGINAL_UNMODIFIED_GENUINE_MATHWORKS_R2026B';
report.original_unmodified=true;
report.release=version('-release');report.matlab_version=version;
report.computer=computer;report.mkl_cbwr=getenv('MKL_CBWR');
report.max_num_comp_threads=maxNumCompThreads;
report.raw_input_sha256=lock.raw_input_sha256;
report.rust_frozen_forecast_sha256=lock.native_frozen_sha256;
report.rust_private_preoracle_commit=lock.private_frozen_preoracle_commit;
report.repetitions=2;report.cases=records;
out=getenv('V12_ORIGINAL_FULL_OUTPUT');assert(~isempty(out));
fd=fopen(fullfile(root,out),'w');assert(fd>0);
closefile=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
end

function v=pack_original_binary64(original)
assert(isa(original,'double') && isreal(original));
v=struct();
v.shape=double(size(original));
v.hex=cellstr(num2hex(original(:)));
end
