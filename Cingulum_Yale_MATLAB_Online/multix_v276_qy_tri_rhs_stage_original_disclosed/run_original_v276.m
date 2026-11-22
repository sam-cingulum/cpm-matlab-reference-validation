function run_original_v276()
% V276 original-only SOURCE-DISCLOSED partition of RHS-layout binary64
% effects into public Q'*B and R\(Q'*B) vs original full A\B.
% Genuine R2026b Update 1, approved AMD, original first-blind gates immutable.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.classification,'CINGULUM_V263_PROSPECTIVE_TERMINAL_ZERO_REDUCED_ROW_MLDIVIDE'));
assert(raw.seed==202611220263&&numel(raw.cases)==48);
assert(strcmp(raw.first_original_blind_V252_verdict_unchanged,'FAIL'));
ks=[0 7];
widths=[1 2 3 4 5 6 7 8 9 12 16];
rows=struct('id',{},'rep',{},'n',{},'p',{},'pads',{});
for rep=1:2
 for ci=1:48
  c=raw.cases(ci);n=double(c.n);p=double(c.p);
  assert(ismember(n,[35 36 43 44 47 48 61 62 71 72 87 88]));
  assert(ismember(p,[3 4 5 6]));
  A=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  b=hex2num(char(c.b_hex));b=b(:);
  assert(all(A(end,:)==0)&&b(end)==0);
  pads=cell(numel(ks),1);
  for ki=1:numel(ks)
   z=ks(ki);
   Az=[A;zeros(z,p)];bz=[b;zeros(z,1)];
   [Q,R,P]=qr(Az,'econ','vector');
   assert(all(size(Q)==[n+z p])&&all(size(R)==[p p])&&isequal(sort(P),1:p));
   qsolo=Q'*bz;
   trsolo=R\qsolo;
   ref=zeros(p,1);ref(P)=trsolo;
   originalsolo=Az\bz;
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    width=widths(wi);
    B=repmat(bz,1,width);
    Qy=Q'*B;
    Tr=R\Qy;
    fixed=R\repmat(qsolo,1,width);
    ut=linsolve(R,Qy,struct('UT',true));
    mx=Az\B;
    assert(all(size(Qy)==[p width])&&all(size(Tr)==[p width]));
    assert(all(isfinite(Qy(:)))&&all(isfinite(Tr(:)))&&all(isfinite(mx(:))));
    outTr=zeros(p,width);outTr(P,:)=Tr;
    outFixed=zeros(p,width);outFixed(P,:)=fixed;
    outUt=zeros(p,width);outUt(P,:)=ut;
    ps=cell(width,1);
    for j=1:width
      ps{j}=struct('column_index_onebased',j,...
        'source_public_Qtranspose_B_hex',{bits(Qy(:,j))},...
        'source_public_Rbackslash_Qtranspose_B_hex',{bits(outTr(:,j))},...
        'source_public_Rbackslash_fixed_single_Qy_hex',{bits(outFixed(:,j))},...
        'source_public_UTsolve_Qtranspose_B_hex',{bits(outUt(:,j))},...
        'source_original_Abackslash_B_hex',{bits(mx(:,j))});
    end
    panels{wi}=struct('rhs_width',width,'columns',{ps});
   end
   pads{ki}=struct('extra_terminal_zero_rows',z,'total_n',n+z,...
     'source_QR_pivot_onebased',P,...
     'source_QR_R_colmajor_hex',{bits(R(:))},...
     'source_Qtranspose_single_b_hex',{bits(qsolo)},...
     'source_explicit_QR_single_beta_hex',{bits(ref)},...
     'source_original_single_beta_hex',{bits(originalsolo)},...
     'rhs_width_panels',{panels});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'pads',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==96);
for i=1:48
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+48),'rep');
 assert(isequal(a,b),'Original V276 source-only stage probe not bitwise repeatable');
end
out=struct('classification',...
  'V276_GENUINE_R2026B_SOURCE_DISCLOSED_SPLIT_QTRANSPOSE_B_VS_TRIANGULAR_RHS_WIDTH',...
 'source_disclosed',true,'new_first_original_blind_certificate',false,...
 'historical_V252_full17_first_blind','FAIL',...
 'historical_V263_reduced_first_blind','PASS_216_OF_216',...
 'comprehensive_V12','SEALED',...
 'proprietary_MathWorks_source_exported',false,...
 'source_original_run',getenv('GITHUB_RUN_ID'),'release',version,...
 'mkl_cbwr',getenv('MKL_CBWR'),'cases',48,'repetitions',2,...
 'input_sha256','01f935d0b92f89f14589d4e6d35fb99d96bbea746a808b7eb4771a4461e66526',...
 'extra_zero_rows',ks,'rhs_widths',widths,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
function out=bits(v)
out=cellstr(num2hex(double(v(:))));
end
