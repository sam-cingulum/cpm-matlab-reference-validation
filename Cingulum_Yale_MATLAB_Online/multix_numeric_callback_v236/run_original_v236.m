function run_original_v236()
% V236 SOURCE-DISCLOSED R2026b callback numeric workspace audit.
% Do not inspect or export proprietary MathWorks source. Query ONLY finite
% double vectors with coefficient-sized dimensions from the direct runtime
% caller of an independently authored robustfit weight callback.
% Original default robustfit is separately executed without instrumentation.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND'));
assert(raw.seed==202611220211 && numel(raw.cases)==48);
global V236_RECORDS V236_NUM_COEFFICIENTS V236_CALLBACK_INDEX;
rows=struct('id',{},'p',{},'n',{},'rep',{},...
 'unchanged_original_b_equal_instrumented',{},...
 'unchanged_original_all_stats_equal_instrumented',{},...
 'total_callbacks',{},'captured_snapshots',{},'original_b_hex',{});
for rep=1:2
 for i=1:48
  c=raw.cases(i);
  n=double(c.n);p=double(c.p);
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,p);
  y=hex2num(char(c.y_hex));y=y(:);
  [borig,so]=robustfit(X,y);
  V236_RECORDS={};V236_NUM_COEFFICIENTS=p+1;V236_CALLBACK_INDEX=0;
  [bc,sc]=robustfit(X,y,@audited_bisquare,4.685);
  assert(isequal(num2hex(borig),num2hex(bc)));
  names=fieldnames(so);
  assert(numel(names)==17);
  same=true;
  for j=1:numel(names)
   name=names{j};
   same=same && isequal(num2hex(so.(name)),num2hex(sc.(name)));
  end
  assert(same);
  rows(end+1)=struct('id',c.id,'p',p,'n',n,'rep',rep,...
   'unchanged_original_b_equal_instrumented',true,...
   'unchanged_original_all_stats_equal_instrumented',true,...
   'total_callbacks',V236_CALLBACK_INDEX,...
   'captured_snapshots',{V236_RECORDS},...
   'original_b_hex',{bits(borig)}); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for j=1:48
 a=rmfield(rows(j),'rep');b=rmfield(rows(j+48),'rep');
 assert(isequal(a,b),'caller numeric callback observations not repeated exactly');
end
result=struct('classification','V236_SOURCE_DISCLOSED_ORIGINAL_ONLY_RUNTIME_NUMERIC_CALLBACK_PROBE',...
 'source_disclosed',true,'new_original_first_blind',false,...
 'user_callback_original_method_unchanged',true,...
 'exported_proprietary_source_code',false,...
 'caller_variable_names_persisted',false,...
 'only_finite_coefficient_length_numeric_vectors_persisted',true,...
 'run',getenv('GITHUB_RUN_ID'),'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'raw_input_sha256','5836d8f460b64c889feda69ee69dc4792a5ff85bf120600f346171150eb2a559',...
 'repetitions',2,'cases',48,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(result));
end
function w=audited_bisquare(u)
global V236_RECORDS V236_NUM_COEFFICIENTS V236_CALLBACK_INDEX;
V236_CALLBACK_INDEX=V236_CALLBACK_INDEX+1;
w=double(abs(u)<1).*(1-u.^2).^2;
candidate_values={};
numeric_caller_available=false;
error_id='none';
try
 % whos supplies metadata only; do NOT request original source text.
 metadata=evalin('caller','whos');
 numeric_caller_available=true;
 for j=1:numel(metadata)
  candidate=metadata(j);
  dims=candidate.size;
  if ~strcmp(candidate.class,'double') || prod(dims)~=V236_NUM_COEFFICIENTS
   continue;
  end
  % Numeric vectors only. Names are deliberately not persisted.
  value=evalin('caller',candidate.name);
  if isa(value,'double') && isreal(value) && isvector(value) ...
       && numel(value)==V236_NUM_COEFFICIENTS && all(isfinite(value(:)))
   candidate_values{end+1}=bits(value); %#ok<AGROW>
  end
 end
catch ME
 error_id=ME.identifier;
end
entry=struct('callback_ordinal',V236_CALLBACK_INDEX,...
 'u_hex',{bits(u)},'w_hex',{bits(w)},...
 'direct_caller_numeric_introspection_available',numeric_caller_available,...
 'captured_coefficient_length_vectors',{candidate_values},...
 'numeric_caller_diagnostic_error_id',error_id);
V236_RECORDS{end+1}=entry;
end
function b=bits(v)
b=cellstr(num2hex(double(v(:))));
end
