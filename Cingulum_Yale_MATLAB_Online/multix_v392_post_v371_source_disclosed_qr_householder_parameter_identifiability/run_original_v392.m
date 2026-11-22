function run_original_v392()
% V392 original-only MathWorks R2026b Update1: PUBLIC explicit Q's first
% two columns and public R/(Q'*B) versus true hidden A\B. This is a
% source-DISCLOSED diagnostic after immutable V371 firstblind FAIL.
% Never uses any Rust numerical outputs; Q is a public QR diagnostic, not
% a trusted surrogate for the hidden backslash response transform.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
inputfile=fullfile(root,'..','multix_v377_post_v371_two_reflector_sparse_impulses','input.json');
d=jsondecode(fileread(inputfile));
assert(strcmp(d.classification,'V377_POST_V371_SOURCE_DISCLOSED_ORIGINAL_ONLY_TWO_REFLECTOR_SPARSE_IMPULSES'));
assert(d.source_disclosed_after_V371 && ~d.original_MATLAB_numerical_results_consulted);
assert(~d.original_source_reads_independent_Rust_forecast);
assert(strcmp(d.V371_first_original_blind,'IMMUTABLE_FAIL_133582_OF_182784'));
assert(strcmp(d.V366_first_original_blind,'PASS_365568_OF_365568'));
assert(strcmp(d.V12,'SEALED'));
assert(d.case_count==8 && numel(d.cases)==8);
widths=[1 11 12 16];pads=[0 1 7 16];
rows=struct('id',{},'rep',{},'n',{},'p',{},'pads',{});
for rep=1:2
 for ci=1:8
  c=d.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[48 65])&&ismember(p,[9 10 11 12]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B=reshape(hex2num(char(c.b16_colmajor_hex)),n,16);
  assert(all(isfinite(A(:)))&&all(isfinite(B(:))));
  assert(all(A(end,:)==0)&&all(B(end,:)==0));
  assert(rank(A(1:end-1,:))==p);
  pres=cell(numel(pads),1);
  for zi=1:numel(pads)
   z=pads(zi);X=[A;zeros(z,p)];Y=[B;zeros(z,16)];
   [Q,R,P]=qr(X,'econ','vector');
   assert(isequal(P,1:p),'pivot must be exact identity');
   assert(isequal(size(Q),[n+z p]));
   assert(all(diag(R)~=0)&&any(any(triu(R,1)~=0)));
   q2=double(Q(:,1:2));qdiag=[double(Q(1,1));double(Q(2,2))];
   assert(all(isfinite(q2(:))) && all(isfinite(qdiag)));
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);yw=Y(:,1:w);
    projected=Q'*yw;
    explicit=R\projected;
    hidden=X\yw;
    assert(all(isfinite(projected(:)))&&all(isfinite(hidden(:)))&&all(isfinite(explicit(:))));
    assert(isequal(size(hidden),[p w])&&isequal(size(explicit),[p w]));
    hcols=cell(w,1);ecols=cell(w,1);
    for j=1:w
     hcols{j}=cellstr(num2hex(double(hidden(:,j))));
     ecols{j}=cellstr(num2hex(double(explicit(:,j))));
    end
    panels{wi}=struct('w',w,...
     'original_hidden_A_backslash_B_columns',{hcols},...
     'original_public_R_backslash_QtB_columns',{ecols},...
     'original_public_QtB_first2_column_major_bits',{cellstr(num2hex(reshape(double(projected(1:2,:)),[],1)))});
   end
   pres{zi}=struct('z',z,...
    'original_public_Q_first2_column_major_bits',{cellstr(num2hex(q2(:)))},...
    'original_public_Q_diagonal_first_two_bits',{cellstr(num2hex(qdiag))},...
    'original_public_R_colmajor_bits',{cellstr(num2hex(double(R(:))))},...
    'original_public_pivot_one_based',double(P(:).'),...
    'panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'pads',{pres}); %#ok<AGROW>
 end
end
assert(numel(rows)==16);
for i=1:8
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+8),'rep');
 assert(isequal(a,b),'new V392 genuine MATLAB original numerical repeats not identical');
end
out=struct(...
 'classification','V392_GENUINE_MATHWORKS_R2026B_POST_V371_SOURCE_DISCLOSED_EXPLICIT_Q_HOUSEHOLDER_DIAGNOSTIC',...
 'source_disclosed_after_V371',true,...
 'original_reads_Rust_forecast',false,...
 'reference_source_V377_input_sha256','ef95b3a983d15454b6ca0e4625893039cc896b77fe792a2108166543301c1556',...
 'original_run_id',getenv('GITHUB_RUN_ID'),'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'case_count',8,'repetitions',2,'widths',widths,'pads',pads,...
 'V371_firstblind','IMMUTABLE_FAIL_133582_OF_182784',...
 'V366_firstblind','PASS_365568_OF_365568','V12','SEALED',...
 'public_explicit_Q_is_not_hidden_A_backslash_B_kernel',true,...
 'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
