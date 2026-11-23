function run_original_v441()
% V441 SOURCE-DISCLOSED hidden A\B cancellation and physical-panel diagnostic.
% ORIGINAL MathWorks MATLAB R2026b Update 1 only on approved AMD EPYC.
% Not a new first-blind certification; no private Rust numeric output is read.
% Publish and verify frozen source SHA before running on approved hosts.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
assert(isunix && isfile('/proc/cpuinfo'));
cpu=fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'), ...
  'V441 requires a preregistered original approved AMD EPYC host');
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,...
 'V441_SOURCE_DISCLOSED_R2026B_TWO_REFLECTOR_CANCELLATION_ORIGINAL_ONLY'));
assert(d.source_disclosed_diagnostic && ~d.new_original_firstblind_candidate);
assert(~d.original_MATLAB_numerical_outputs_read && ~d.original_only_runner_reads_Rust_predictions);
assert(d.seed==202611230441 && d.matrix_count==8 && d.probe_count==320);
assert(isequal(double(d.n_values(:).'),[48 65]));
assert(isequal(double(d.p_values(:).'),[9 10 11 12]));
assert(isequal(double(d.widths(:).'),[1 2 11 12 13 16]));
assert(isequal(double(d.padding(:).'),[0 1 7 16]));
assert(strcmp(d.original_V377_input_sha256,...
 'ef95b3a983d15454b6ca0e4625893039cc896b77fe792a2108166543301c1556'));
assert(strcmp(d.V12,'SEALED'));
assert(numel(d.matrices)==8 && numel(d.cases)==320);
panels=double(d.widths(:).'); padding=double(d.padding(:).');
matrixIds=string({d.matrices.id});
assert(numel(unique(matrixIds))==8);
matrices=cell(8,1);
for i=1:8
 m=d.matrices(i);n=double(m.n);p=double(m.p);
 assert(ismember(n,[48 65]) && ismember(p,[9 10 11 12]));
 A=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
 assert(all(isfinite(A(:))) && all(A(end,:)==0) && rank(A)==p);
 matrices{i}=A;
end
rows=struct('id',{},'rep',{},'n',{},'p',{},'probe',{},'layout',{},'pads',{});
for rep=1:2
 for ci=1:320
  c=d.cases(ci);mi=find(matrixIds==string(c.matrix_id));
  assert(isscalar(mi),'matrix id lookup');
  A=matrices{mi};[n,p]=size(A);
  assert(numel(c.b_colmajor_hex)==n);
  b=double(hex2num(char(c.b_colmajor_hex)));
  b=reshape(b,n,1);
  assert(all(isfinite(b)) && b(end)==0);
  assert(ismember(string(c.layout),["repeated","alternating_sign"]));
  B16=repmat(b,1,16);
  if strcmp(c.layout,'alternating_sign')
   B16(:,2:2:16)=-B16(:,2:2:16);
  end
  padCell=cell(numel(padding),1);
  for zi=1:numel(padding)
   z=padding(zi);
   X=[A;zeros(z,p)];
   [~,R,perm]=qr(X,'econ','vector');
   assert(isequal(double(perm(:).'),1:p) && all(diag(R)~=0));
   allPanels=cell(numel(panels),1);
   for wi=1:numel(panels)
    w=panels(wi); Y=[B16(:,1:w);zeros(z,w)];
    sol=X\Y;
    assert(isequal(size(sol),[p w]) && all(isfinite(sol(:))));
    entries=cell(w,1);
    for j=1:w
     entries{j}=cellstr(num2hex(double(sol(:,j))));
    end
    allPanels{wi}=struct('w',w,'original_full_beta_columns_hex',{entries});
   end
   padCell{zi}=struct('z',z,'original_R_bits',{cellstr(num2hex(double(R(:))))},...
      'original_pivots_onebased',double(perm(:).'),'panels',{allPanels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,... %#ok<AGROW>
   'probe',c.probe,'layout',c.layout,'pads',{padCell});
 end
end
assert(numel(rows)==640);
for i=1:320
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+320),'rep');
 assert(isequal(a,b),'Original MATLAB response reductions not repeatable');
end
out=struct(...
 'classification','V441_GENUINE_R2026B_SOURCE_DISCLOSED_HIDDEN_PANEL_CANCELLATION',...
 'NOT_new_original_firstblind',true,'V12','SEALED',...
 'original_only_MATLAB_reads_independent_Rust_values',false,...
 'original_source_input_sha256','fd6422211331eb71c6609e251ffb50a69b9c3a2338c077fd388f972e3b492457',...
 'original_run_id',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_matrix_count',8,'probe_count',320,'repetitions',2,...
 'padding',padding,'widths',panels,...
 'solver_panels_per_repetition',7680,...
 'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
