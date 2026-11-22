function run_original_v341()
% Source-DISCLOSED post-V340 FAIL: original MATLAB R2026b publicly exposed
% pivoted QR stage on frozen original-only source V338 matrix inputs.
% Important: public QR is NOT declared to be the hidden internal A\B stage.
% V340 genuine first-blind FAIL 63871/182784 remains immutable forever.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
input_path=fullfile(root,'..','multix_v338_new_firstblind_p9p12','input.json');
d=jsondecode(fileread(input_path));
assert(strcmp(d.classification,'V338_NEW_GENUINE_ORIGINAL_FIRST_BLIND_P9P12_FULL_MLDIVIDE'));
assert(d.seed==202611220338 && d.cohorts==32 && numel(d.cases)==32);
assert(strcmp(d.historical_V308,'IMMUTABLE_FAIL_54741_OF_57816'));
assert(strcmp(d.historical_V332,'PASS_261120_OF_261120'));
assert(strcmp(d.historical_V336,'PASS_261120_OF_261120'));
assert(strcmp(d.universal_V12,'SEALED'));
padding=[0 1 7 16];
rows=struct('id',{},'rep',{},'p',{},'n',{},'family',{},'public_qr_padding',{});
for rep=1:2
 for ci=1:32
  c=d.cases(ci);p=double(c.p);n=double(c.n);
  assert(ismember(p,[9 10 11 12])&&n>p);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B16=reshape(hex2num(char(c.rhs16_colmajor_hex)),n,16);
  assert(isequal(size(A),[n p]) && isequal(size(B16),[n 16]));
  assert(all(isfinite(A(:))) && all(isfinite(B16(:))));
  assert(all(A(end,:)==0)&&all(B16(end,:)==0));
  assert(isequal(B16(:,1),B16(:,2)));
  assert(rank(A(1:end-1,:))==p);
  pads=cell(numel(padding),1);
  for zi=1:numel(padding)
   z=padding(zi);
   X=[A;zeros(z,p)];
   [Q,R,P]=qr(X,'econ','vector');
   assert(isequal(sort(P),1:p));
   assert(isequal(size(R),[p p])&&all(isfinite(R(:))));
   assert(all(diag(R)~=0));
   response=[B16(:,1:2);zeros(z,2)];
   public_Qtb=Q'*response; % PUBLIC QR diagnostic, not hidden mldivide internals!
   assert(all(isfinite(public_Qtb(:))));
   pads{zi}=struct('padding',z,...
     'public_QR_R_colmajor_hex',{cellstr(num2hex(double(R(:))))},...
     'public_QR_permutation_onebased',P,...
     'public_QtB_two_col_colmajor_hex',{cellstr(num2hex(double(public_Qtb(:))))});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'p',p,'n',n,'family',c.family,...
      'public_qr_padding',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==64);
for i=1:32
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+32),'rep');
 assert(isequal(a,b),'genuine original public QR repeats differ');
end
result=struct(...
 'classification','V341_GENUINE_R2026B_SOURCE_DISCLOSED_POST_V340_PUBLIC_PIVOTED_QR_DIAGNOSTIC',...
 'source_disclosed_after_firstblind_V340',true,...
 'V340_first_original_blind','IMMUTABLE_FAIL_63871_OF_182784',...
 'V308_first_original_blind','IMMUTABLE_FAIL_54741_OF_57816',...
 'V332_first_original_blind','PASS_261120_OF_261120',...
 'V336_first_original_blind','PASS_261120_OF_261120',...
 'V12','SEALED',...
 'original_public_R_not_guaranteed_hidden_mldivide_R',true,...
 'source_original_run',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_public_input_sha256','6ac321c1de1c034db55edebf2aa4073174fa3436b810855e6a2297ee372cfb41',...
 'case_count',32,'original_repetitions',2,'padding',padding,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(result));
end
