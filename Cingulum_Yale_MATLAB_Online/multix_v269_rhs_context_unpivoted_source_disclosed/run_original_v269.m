function run_original_v269()
% V269 source-disclosed full-length mldivide RHS-coordinate / unpivoted QR
% probe. Uses ONLY frozen synthetic public V263 matrices and original MATLAB
% built-in operators. Retains V252 raw robustfit FAIL, V263 reduced-row PASS.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,'CINGULUM_V263_PROSPECTIVE_TERMINAL_ZERO_REDUCED_ROW_MLDIVIDE'));
assert(raw.seed==202611220263 && numel(raw.cases)==48);
assert(strcmp(raw.first_original_blind_V252_verdict_unchanged,'FAIL'));
ks=[0 6 7 17];
rows=struct('id',{},'rep',{},'n',{},'p',{},'source_padding_stages',{});
for rep=1:2
 for ci=1:48
  c=raw.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[35 36 43 44 47 48 61 62 71 72 87 88]));
  assert(ismember(p,[3 4 5 6]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(all(A(end,:)==0)&&b(end)==0);
  stages=cell(numel(ks),1);
  for ki=1:numel(ks)
   z=ks(ki);
   Az=[A;zeros(z,p)]; bz=[b;zeros(z,1)];
   m=n+z;
   B=[bz zeros(m,1)];
   B2=[zeros(m,1) bz];
   Bsame=[bz bz];
   B3=[zeros(m,1) bz zeros(m,1)];
   solo=Az\bz;
   paired=Az\B;
   flipped=Az\B2;
   same=Az\Bsame;
   triple=Az\B3;
   assert(isequal(size(paired),[p 2]) && isequal(size(flipped),[p 2]) ...
    && isequal(size(same),[p 2]) && isequal(size(triple),[p 3]));
   assert(all(isfinite([solo;paired(:);flipped(:);same(:);triple(:)])));
   [Qn,Rn]=qr(Az,'econ');
   assert(all(size(Qn)==[m p])&&all(size(Rn)==[p p]));
   qyn=Qn'*bz;
   betan=Rn\qyn;
   decomp_available=false;decompb=NaN(p,1);
   try
     d=decomposition(Az,'qr');
     decompb=d\bz;
     decomp_available=isequal(size(decompb),[p 1]) && all(isfinite(decompb));
   catch
     decomp_available=false;
   end
   if ~decomp_available
     decompb=NaN(p,1);
   end
   stages{ki}=struct( ...
    'extra_terminal_zero_rows',z,'total_n',m,'p',p, ...
    'source_single_RHS_b_hex',{bits(solo)}, ...
    'source_pair_rhs_first_b_hex',{bits(paired(:,1))}, ...
    'source_pair_rhs_second_b_hex',{bits(flipped(:,2))}, ...
    'source_identical_two_RHS_first_b_hex',{bits(same(:,1))}, ...
    'source_identical_two_RHS_second_b_hex',{bits(same(:,2))}, ...
    'source_triple_middle_b_hex',{bits(triple(:,2))}, ...
    'source_unpivoted_Q_colmajor_hex',{bits(Qn(:))}, ...
    'source_unpivoted_R_colmajor_hex',{bits(Rn(:))}, ...
    'source_unpivoted_Qtranspose_b_hex',{bits(qyn)}, ...
    'source_unpivoted_QR_b_hex',{bits(betan)}, ...
    'source_decomposition_qr_available',decomp_available, ...
    'source_decomposition_qr_b_hex',{bits(decompb)});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'source_padding_stages',{stages}); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for i=1:48
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+48),'rep');
 assert(isequaln(a,b),'original RHS multi-column must repeat bitwise');
end
out=struct( ...
 'classification','V269_GENUINE_MATHWORKS_SOURCE_DISCLOSED_MULTIRHS_UNPIVOTED_QR', ...
 'source_disclosed',true,'new_first_original_blind_certification',false, ...
 'original_proprietary_MathWorks_source_exported',false, ...
 'historical_V252_full17_first_blind','FAIL', ...
 'historical_V263_reduced_first_blind','PASS_216_OF_216', ...
 'comprehensive_V12','SEALED', ...
 'source_original_run',getenv('GITHUB_RUN_ID'), ...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'), ...
 'cases',48,'repetitions',2,'seed',202611220263, ...
 'raw_input_sha256','01f935d0b92f89f14589d4e6d35fb99d96bbea746a808b7eb4771a4461e66526', ...
 'padding_counts',ks,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
