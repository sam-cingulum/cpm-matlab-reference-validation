function run_original_v359()
% Genuine original MATLAB R2026b, post-V340 SOURCE-DISCLOSED.
% Sparse impulse controls expose physical RHS position effects in full X\B.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(d.classification,'V359_SOURCE_DISCLOSED_POST_V340_GENUINE_ORIGINAL_12_COLUMN_PANEL_SPARSE_IMPULSES'));
assert(d.source_disclosed_after_V340 && ~d.MATLAB_original_numeric_values_seen_by_source);
assert(strcmp(d.V340,'IMMUTABLE_FAIL_63871_OF_182784'));
assert(strcmp(d.V332,'PASS_261120_OF_261120'));
assert(strcmp(d.V336,'PASS_261120_OF_261120'));
assert(strcmp(d.V12,'SEALED'));
assert(d.case_count==16 && numel(d.cases)==16);
widths=[1 2 4 8 11 12 13 16];padding=[0 1 7 16];
assert(isequal(double(d.widths(:).'),widths));
assert(isequal(double(d.padding(:).'),padding));
rows=struct('id',{},'rep',{},'p',{},'n',{},'mode',{},'pads',{});
for rep=1:2
 for ci=1:16
  c=d.cases(ci);p=double(c.p);n=double(c.n);
  assert(ismember(p,[9 10 11 12]) && ismember(n,[48 65]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B=reshape(hex2num(char(c.b16_colmajor_hex)),n,16);
  assert(all(isfinite(A(:)))&&all(isfinite(B(:))));
  assert(all(A(end,:)==0)&&all(B(end,:)==0));
  assert(isequal(B(:,1:4),B(:,13:16)));
  assert(rank(A(1:end-1,:))==p);
  pads=cell(numel(padding),1);
  for zi=1:numel(padding)
   z=padding(zi);X=[A;zeros(z,p)];Y=[B;zeros(z,16)];
   [~,R,P]=qr(X,'econ','vector');
   assert(isequal(P,1:p)&&all(all(triu(R,1)==0)));
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);sol=X\Y(:,1:w);
    assert(isequal(size(sol),[p w]) && all(isfinite(sol(:))));
    panels{wi}=struct('w',w,...
     'first_coefficient_bits',{cellstr(num2hex(double(sol(1,:).')))},...
     'all_coefficients_colmajor_bits',{cellstr(num2hex(double(sol(:))))});
   end
   pads{zi}=struct('z',z,'panels',{panels},'public_r00_bits',num2hex(double(R(1,1))));
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'p',p,'n',n,'mode',c.mode,...
   'pads',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==32);
for i=1:16
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+16),'rep');
 assert(isequal(a,b),'original two numerical runs not identical');
end
result=struct(...
 'classification','V359_GENUINE_MATHWORKS_R2026B_SOURCE_DISCLOSED_TWELVE_PANEL_SPARSE_IMPULSE_ORIGINAL',...
 'source_disclosed_after_V340',true,...
 'original_MATLAB_did_not_read_native_values',true,...
 'source_public_input_sha256','1ff59ba46eda8aaf49c4e81964c8a9af70d1bf8a23aa6dbf7b111f5da75ce043',...
 'V340','IMMUTABLE_FAIL_63871_OF_182784',...
 'V332','PASS_261120_OF_261120','V336','PASS_261120_OF_261120',...
 'V12','SEALED','release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'case_count',16,'repetitions',2,'widths',widths,...
 'padding',padding,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(result));
end
