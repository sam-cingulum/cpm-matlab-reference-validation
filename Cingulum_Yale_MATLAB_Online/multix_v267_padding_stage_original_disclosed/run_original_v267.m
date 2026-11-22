function run_original_v267()
% V267 strictly SOURCE-DISCLOSED numerical decomposition after frozen V263 PASS.
% Genuine public MATLAB R2026b Update 1 only. Never import Rust predictions,
% MATLAB private source or hidden runtime variable names. Original-only stage
% captures Q,R,P,Q'*b, backslash and upper triangular alternatives.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,'CINGULUM_V263_PROSPECTIVE_TERMINAL_ZERO_REDUCED_ROW_MLDIVIDE'));
assert(raw.seed==202611220263 && numel(raw.cases)==48);
assert(~raw.source_original_MATLAB_numeric_results_consulted);
assert(strcmp(raw.first_original_blind_V252_verdict_unchanged,'FAIL'));
ks=[0 1 2 3 4 5 6 7 8 9 16 17 31 32 64];
rows=struct('id',{},'rep',{},'n',{},'p',{},'source_padding_stages',{});
for rep=1:2
 for ci=1:48
  c=raw.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[35 36 43 44 47 48 61 62 71 72 87 88]));
  assert(ismember(p,[3 4 5 6]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(all(A(end,:)==0) && b(end)==0);
  stages=cell(numel(ks),1);
  for ki=1:numel(ks)
   z=ks(ki);
   Az=[A;zeros(z,p)]; bz=[b;zeros(z,1)];
   [Q,R,P]=qr(Az,'econ','vector');
   assert(all(size(Q)==[n+z,p]) && all(size(R)==[p,p]));
   assert(isequal(sort(P),1:p));
   qy=Q'*bz;
   tri=R\qy;
   explicit=zeros(p,1);explicit(P)=tri;
   triUT=linsolve(R,qy,struct('UT',true));
   explicitUT=zeros(p,1);explicitUT(P)=triUT;
   implicit=Az\bz;
   assert(all(isfinite(implicit))&&all(isfinite(qy))&&all(isfinite(explicit)));
   % Non-pivoted augmented QR supplies a public implicit-response diagnostic.
   [~,Raug]=qr([Az bz],'econ');
   assert(all(size(Raug)==[p+1,p+1]));
   augmented=Raug(1:p,1:p)\Raug(1:p,p+1);
   isQ=(z==0 || z==6 || z==7 || z==17 || z==64);
   if isQ
      qbits=bits(Q(:));
   else
      qbits={};
   end
   stages{ki}=struct( ...
    'extra_terminal_zero_rows',z,'total_n',n+z,'p',p,...
    'original_full_backslash_b_hex',{bits(implicit)},...
    'source_qr_pivot_one_based',P,...
    'source_qr_R_colmajor_hex',{bits(R(:))},...
    'source_qr_Q_colmajor_hex',{qbits},...
    'source_qr_explicit_Qtranspose_b_hex',{bits(qy)},...
    'source_explicit_QR_backsolve_b_hex',{bits(explicit)},...
    'source_explicit_QR_linsolve_UT_b_hex',{bits(explicitUT)},...
    'source_augmented_unpivoted_R_colmajor_hex',{bits(Raug(:))},...
    'source_augmented_unpivoted_backsolve_b_hex',{bits(augmented)});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,...
    'source_padding_stages',{stages}); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for i=1:48
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+48),'rep');
 assert(isequal(a,b),'genuine V267 original stage data non-reproducible');
end
out=struct( ...
 'classification','V267_GENUINE_R2026B_SOURCE_DISCLOSED_FULL_LENGTH_PADDING_QR_TRIANGULAR_STAGES', ...
 'source_disclosed',true,'new_first_original_blind_certification',false, ...
 'historic_V263_reduced_first_blind_verdict','PASS_216_OF_216', ...
 'historic_V252_full17_first_blind_verdict','FAIL', ...
 'comprehensive_V12','SEALED', ...
 'original_proprietary_MathWorks_source_exported',false, ...
 'original_runtime_private_names_exported',false, ...
 'source_original_run',getenv('GITHUB_RUN_ID'), ...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'), ...
 'seed',202611220263, ...
 'raw_input_sha256','01f935d0b92f89f14589d4e6d35fb99d96bbea746a808b7eb4771a4461e66526', ...
 'repetitions',2,'cases',48,'extra_zero_rows_tested',ks,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
