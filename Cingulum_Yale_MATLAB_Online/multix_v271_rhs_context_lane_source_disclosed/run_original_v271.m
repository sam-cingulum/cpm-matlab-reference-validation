function run_original_v271()
% V271 original-only SOURCE-DISCLOSED MATLAB R2026b RHS matrix-panel width
% and output coordinate test after V269 established width-specific rounding.
% 48 already-disclosed V263 synthetic full-rank terminal-zero matrices.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,'CINGULUM_V263_PROSPECTIVE_TERMINAL_ZERO_REDUCED_ROW_MLDIVIDE'));
assert(raw.seed==202611220263&&numel(raw.cases)==48);
assert(strcmp(raw.first_original_blind_V252_verdict_unchanged,'FAIL'));
padding=[0 7];
widths=[1 2 3 4 5 6 7 8 9 12 16];
rows=struct('id',{},'rep',{},'n',{},'p',{},'pad_panels',{});
for rep=1:2
 for ci=1:48
  c=raw.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[35 36 43 44 47 48 61 62 71 72 87 88]));
  assert(ismember(p,[3 4 5 6]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(all(A(end,:)==0) && b(end)==0);
  ps=cell(numel(padding),1);
  for zi=1:numel(padding)
   z=padding(zi);
   Az=[A;zeros(z,p)];bz=[b;zeros(z,1)];
   reference=Az\bz;
   d=decomposition(Az,'qr');
   dsingle=d\bz;
   assert(isequaln(size(dsingle),[p,1]));
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    k=widths(wi);
    response=repmat(bz,1,k);
    source_b=Az\response;
    decomp_b=d\response;
    assert(all(size(source_b)==[p k])&&all(size(decomp_b)==[p k]));
    assert(all(isfinite(source_b(:))) && all(isfinite(decomp_b(:))));
    bits_by_col=cell(k,1);
    decomp_bits_by_col=cell(k,1);
    for j=1:k
     bits_by_col{j}=bits(source_b(:,j));
     decomp_bits_by_col{j}=bits(decomp_b(:,j));
    end
    panels{wi}=struct('rhs_width',k,'source_original_column_b_hex',{bits_by_col}, ...
      'source_decomposition_qr_column_b_hex',{decomp_bits_by_col});
   end
   ps{zi}=struct('extra_terminal_zero_rows',z,'total_n',n+z, ...
    'source_single_RHS_b_hex',{bits(reference)}, ...
    'source_decomposition_qr_single_RHS_b_hex',{bits(dsingle)}, ...
    'source_rhs_panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'pad_panels',{ps}); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for i=1:48
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+48),'rep');
 assert(isequal(a,b),'original V271 width/column panel not bitwise reproducible');
end
out=struct('classification', ...
 'V271_GENUINE_MATHWORKS_R2026B_SOURCE_DISCLOSED_RHS_PANEL_WIDTH_AND_COORDINATE', ...
 'source_disclosed',true,'new_first_original_blind_certification',false, ...
 'historical_V252_original_first_blind','FAIL', ...
 'historical_V263_reduced_first_blind','PASS_216_OF_216', ...
 'universal_V12','SEALED', ...
 'original_proprietary_MathWorks_source_exported',false, ...
 'source_original_run',getenv('GITHUB_RUN_ID'),'release',version, ...
 'mkl_cbwr',getenv('MKL_CBWR'),'seed',202611220263, ...
 'raw_input_sha256','01f935d0b92f89f14589d4e6d35fb99d96bbea746a808b7eb4771a4461e66526', ...
 'cases',48,'repetitions',2,'extra_zero_rows_tested',padding, ...
 'RHS_matrix_widths',widths,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
