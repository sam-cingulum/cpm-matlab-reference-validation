function run_original_v292()
% V292 strictly SOURCE-DISCLOSED controlled one-/two-reflector original-only
% MathWorks MATLAB R2026b numerical experiment. Not a prospective parity oracle.
% Public input has ZERO Rust forecasts or original MATLAB numerical values.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
data=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(data.classification,...
 'V292_ORIGINAL_ONLY_SOURCE_DISCLOSED_SINGLE_REFLECTOR_CANCELLATION'));
assert(data.seed==202611220287 && numel(data.cases)==96);
assert(~data.original_MATLAB_numerical_values_consulted);
assert(~data.native_Rust_forecast_used && ~data.new_first_original_blind_certificate);
assert(strcmp(data.V252_first_original_blind_full17,'FAIL'));
assert(strcmp(data.V263_first_original_blind_reduced,'PASS_216_OF_216'));
assert(strcmp(data.V284_first_original_blind_full_length_single,'PASS_1770_OF_1770'));
assert(strcmp(data.V12,'SEALED'));
NS=[7 8 9 15 16 17 31 32 33 63 64 65];
widths=[1 2 3 4 5 6 7 8 9 12 16];
paddings=[0 7];
assert(isequal(data.matrix_lengths(:).',NS));
assert(isequal(data.rhs_widths(:).',widths));
assert(isequal(data.padding_counts(:).',paddings));
rows=struct('id',{},'n',{},'p',{},'mode',{},'rep',{},'zero_padding_original',{});
for rep=1:2
 for ci=1:96
  c=data.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,NS) && p==2);
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(all(size(A)==[n p]) && numel(b)==n);
  assert(all(A(end,:)==0) && b(end)==0);
  assert(all(isfinite(A(:))) && all(isfinite(b)));
  assert(rank(A(1:end-1,:))==p,'source controlled matrix is not full rank');
  pp=cell(numel(paddings),1);
  for zi=1:numel(paddings)
   z=paddings(zi);
   X=[A;zeros(z,p)];
   y=[b;zeros(z,1)];
   [Q,R,P]=qr(X,'econ','vector');
   assert(all(size(Q)==[n+z p]) && all(size(R)==[p p]));
   assert(isequal(sort(P),1:p));
   qsolo=Q'*y;
   ts=R\qsolo;solo_exp=zeros(p,1);solo_exp(P)=ts;
   original_solo=X\y;
   d=decomposition(X,'qr');
   cols=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);
    B=repmat(y,1,w);
    full=X\B;
    dsol=d\B;
    assert(isequal(size(full),[p w]) && all(isfinite(full(:))));
    assert(isequal(size(dsol),[p w]));
    Qy=Q'*B;
    projected=R\Qy;
    projected0=zeros(p,w);projected0(P,:)=projected;
    inferred=R*full(P,:);
    positions=cell(w,1);
    for j=1:w
     positions{j}=struct('col_onebased',j,...
      'source_full_original_backslash_hex',{bits(full(:,j))},...
      'source_decomposition_qr_original_backslash_hex',{bits(dsol(:,j))},...
      'source_public_Qtranspose_B_hex',{bits(Qy(:,j))},...
      'source_public_QR_triangular_solution_hex',{bits(projected0(:,j))},...
      'source_inferred_effective_QtransposeB_from_R_times_full_beta_hex',{bits(inferred(:,j))});
    end
    cols{wi}=struct('rhs_width',w,'positions',{positions});
   end
   pp{zi}=struct('terminal_zero_padding',z,'total_n',n+z,...
     'public_Q_colmajor_hex',{bits(Q(:))},...
     'public_R_colmajor_hex',{bits(R(:))},...
     'public_pivot_onebased',P,...
     'source_public_Qtranspose_single_hex',{bits(qsolo)},...
     'source_original_solo_full_backslash_hex',{bits(original_solo)},...
     'source_explicit_QR_single_beta_hex',{bits(solo_exp)},...
     'RHS_width_panels',{cols});
  end
  rows(end+1)=struct('id',c.id,'n',n,'p',p,'mode',c.mode,'rep',rep,...
    'zero_padding_original',{pp}); %#ok<AGROW>
 end
end
assert(numel(rows)==192);
for i=1:96
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+96),'rep');
 assert(isequal(a,b),'V292 original numerical result must repeat bitwise');
end
out=struct('classification',...
 'V292_GENUINE_R2026B_SOURCE_DISCLOSED_SINGLE_REFLECTOR_CANCELLATION_RHS_LANES',...
 'source_disclosed',true,'new_first_original_blind_certificate',false,...
 'V252_first_original_blind_full17','FAIL',...
 'V263_first_original_blind_reduced','PASS_216_OF_216',...
 'V284_first_original_blind_full_length_single','PASS_1770_OF_1770',...
 'comprehensive_V12','SEALED',...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'original_mathworks_proprietary_code_exported',false,...
 'source_public_input_sha256','4cc2d04d406e54fefb923ad94a8c12f4b5869fce74141ebe75b46c539e7c1dd8',...
 'cases',96,'repetitions',2,'n_values',NS,'padding_counts',paddings,...
 'rhs_widths',widths,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function h=bits(v)
h=cellstr(num2hex(double(v(:))));
end
