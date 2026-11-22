function run_original_v377()
% Genuine MATLAB R2026b Update1: SOURCE-DISCLOSED after immutable V371 FAIL.
% Original full A\B and explicitly PUBLIC Q'*B shown as DIFFERENT oracles.
% Never reads any Rust numerical output or uses Octave as a substitute.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,'V377_POST_V371_SOURCE_DISCLOSED_ORIGINAL_ONLY_TWO_REFLECTOR_SPARSE_IMPULSES'));
assert(d.source_disclosed_after_V371 && ~d.original_MATLAB_numerical_results_consulted);
assert(~d.original_source_reads_independent_Rust_forecast);
assert(d.case_count==8 && numel(d.cases)==8);
assert(strcmp(d.V369_original_only_input_SHA256,'ed37acd5118b127caa4a46b3b7082c8a4d3007d6c208668902b91a6a1838f7ef'));
assert(strcmp(d.V371_first_original_blind,'IMMUTABLE_FAIL_133582_OF_182784'));
assert(strcmp(d.V366_first_original_blind,'PASS_365568_OF_365568'));
assert(strcmp(d.V12,'SEALED'));
widths=[1 2 4 8 11 12 13 16];padvec=[0 1 7 16];
assert(isequal(double(d.widths(:).'),widths));
assert(isequal(double(d.padding(:).'),padvec));
rows=struct('id',{},'rep',{},'n',{},'p',{},'pads',{});
for rep=1:2
 for ci=1:8
  c=d.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[48 65]) && ismember(p,[9 10 11 12]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B=reshape(hex2num(char(c.b16_colmajor_hex)),n,16);
  assert(all(isfinite(A(:)))&&all(isfinite(B(:))));
  assert(all(A(end,:)==0)&&all(B(end,:)==0));
  assert(isequal(B(:,1:4),B(:,13:16)));
  assert(isequal(B(:,9),B(:,10)));
  assert(rank(A(1:end-1,:))==p);
  pads=cell(numel(padvec),1);
  for zi=1:numel(padvec)
   z=padvec(zi);X=[A;zeros(z,p)];Y=[B;zeros(z,16)];
   [Q,R,P]=qr(X,'econ','vector');
   assert(isequal(sort(P),1:p));
   assert(all(diag(R)~=0));
   assert(any(any(triu(R,1)~=0)),'source design unexpectedly diagonal');
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);
    full=X\Y(:,1:w);
    projected=Q'*Y(:,1:w);
    assert(isequal(size(full),[p w])&&isequal(size(projected),[p w]));
    assert(all(isfinite(full(:)))&&all(isfinite(projected(:))));
    cols=cell(w,1);
    for j=1:w
     cols{j}=cellstr(num2hex(double(full(:,j))));
    end
    panels{wi}=struct('w',w,...
      'original_full_A_backslash_B_column_bits',{cols},...
      'original_public_QtB_first2_colmajor_bits',{cellstr(num2hex(reshape(double(projected(1:2,:)),[],1)))});
   end
   pads{zi}=struct('z',z,'panels',{panels},...
     'public_R_colmajor_bits',{cellstr(num2hex(double(R(:))))},...
     'public_pivot_one_based',double(P(:).'));
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,...
    'pads',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==16);
for i=1:8
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+8),'rep');
 assert(isequal(a,b),'original repeated MATLAB numerical values differ');
end
result=struct(...
 'classification','V377_GENUINE_SOURCE_DISCLOSED_R2026B_TWO_REFLECTOR_SPARSE_IMPULSE_MLDIVIDE_AND_PUBLIC_QTB',...
 'source_disclosed_after_V371',true,...
 'original_only_no_Rust_numerical_input',true,...
 'public_input_sha256','ef95b3a983d15454b6ca0e4625893039cc896b77fe792a2108166543301c1556',...
 'V371_firstblind','IMMUTABLE_FAIL_133582_OF_182784',...
 'V366_firstblind','PASS_365568_OF_365568',...
 'V12','SEALED','release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'case_count',8,'repetitions',2,'widths',widths,'padding',padvec,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(result));
end
