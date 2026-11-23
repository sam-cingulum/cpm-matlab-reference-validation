function run_original_v524()
% Genuine MATLAB R2026b Update 1 original-only holdout on eight unseen X matrices.
% This runner never reads Rust forecasts or prior numerical answers.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
assert(strcmp(getenv('MKL_NUM_THREADS'),'1'));
assert(strcmp(getenv('OMP_NUM_THREADS'),'1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
cpu=fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));
root=fileparts(mfilename('fullpath'));
source=fullfile(root,'..','multix_v523_unseen_n48_n65_rhs_microkernel','input.json');
s=jsondecode(fileread(source));
assert(strcmp(s.classification,'V523_NEW_X_SOURCE_UNSEEN_R2026B_QR_RHS_MICROKERNEL_INPUT'));
assert(s.source_only && s.NOT_new_firstblind && strcmp(s.V12,'SEALED'));
assert(~s.original_MATLAB_numerical_outputs_read && ~s.independent_Rust_outputs_read);
assert(~s.source_original_only_reads_Rust_values && s.original_repetitions==2);
assert(s.case_count==96 && s.matrix_count==8);
assert(numel(s.cases)==96 && numel(s.matrices)==8);
matIds=string({s.matrices.id});
assert(numel(unique(matIds))==8);
widths=[1 2 11 12 13 23 24];
variants=["unmodified","interior_reverse","alternating_sign"];
layouts=["repeated","signed_power2"];
assert(isequal(double(s.widths(:).'),widths));
assert(isequal(string(s.rhs_variants(:).'),variants));
assert(isequal(string(s.layouts(:).'),layouts));
assert(isequal(double(s.padding_n48(:).'),[0 2 3 7]));
assert(isequal(double(s.padding_n65(:).'),[0 1 2 7]));
rows=struct('id',{},'rep',{},'n',{},'p',{},'variant',{},'layout',{},'pads',{});
for rep=1:2
 for ci=1:96
  c=s.cases(ci);mi=find(matIds==string(c.matrix_id));assert(isscalar(mi));
  m=s.matrices(mi);n=double(m.n);p=double(m.p);
  assert(ismember(n,[48 65]) && ismember(p,[9 10 11 12]));
  X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  originalB=reshape(hex2num(char(c.b_colmajor_hex)),n,1);
  assert(all(isfinite(X(:))) && all(isfinite(originalB)));
  assert(all(X(end,:)==0) && originalB(end)==0);
  zvec=[0 2 3 7];if n==65;zvec=[0 1 2 7];end
  for vi=1:numel(variants)
   variant=variants(vi);
   b=originalB;
   if variant=="interior_reverse"
    b(1:n-1)=flipud(b(1:n-1));
   elseif variant=="alternating_sign"
    b(2:2:n-1)=-b(2:2:n-1);
   end
   assert(b(end)==0 && all(isfinite(b)));
   for li=1:numel(layouts)
    layout=layouts(li);Y=repmat(b,1,24);
    if layout=="signed_power2"
     for j=1:24
      scale=pow2(1,mod(j-1,5)-2);
      if mod(j,2)==0;scale=-scale;end
      Y(:,j)=b*scale;
     end
    end
    pads=cell(numel(zvec),1);
    for zi=1:numel(zvec)
     z=zvec(zi);Xp=[X;zeros(z,p)];Yp=[Y;zeros(z,24)];
     [Q,R,P]=qr(Xp,'econ','vector');
     assert(isequal(double(P(:).'),1:p));
     D=decomposition(Xp,'qr');
     rfirst={num2hex(R(1,1)),num2hex(R(1,2)),num2hex(R(2,2))};
     panels=cell(numel(widths),1);
     for wi=1:numel(widths)
      w=widths(wi);Z=Yp(:,1:w);
      hidden=Xp\Z;
      cached=D\Z;
      qtb=Q'*Z;
      explicit=R\qtb;
      assert(all(isfinite(hidden(:))) && all(isfinite(cached(:))) && all(isfinite(qtb(:))) && all(isfinite(explicit(:))));
      assert(isequal(size(hidden),[p w]) && isequal(size(cached),[p w]));
      columns=1;if w>12;columns=[1 13];end
      if w==24;columns=[1 13 24];end
      selected=cell(numel(columns),1);
      for si=1:numel(columns)
       j=columns(si);
       selected{si}=struct( ...
        'column_onebased',j, ...
        'hidden_first2_hex',{cellstr(num2hex(double(hidden(1:2,j))))}, ...
        'cached_decomposition_first2_hex',{cellstr(num2hex(double(cached(1:2,j))))}, ...
        'explicit_qr_first2_hex',{cellstr(num2hex(double(explicit(1:2,j))))}, ...
        'public_qtb_first2_hex',{cellstr(num2hex(double(qtb(1:2,j))))});
      end
      panels{wi}=struct('w',w,'selected_columns',{selected});
     end
     pads{zi}=struct('z',z,'public_r_first2_hex',{rfirst},'pivots',double(P(:).'), 'panels',{panels});
    end
    rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p, ...
     'variant',char(variant),'layout',char(layout),'pads',{pads}); %#ok<AGROW>
   end
  end
 end
end
assert(numel(rows)==1152);
for i=1:576
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+576),'rep');
 assert(isequal(a,b),'V524 original repetition differed in raw numerical outputs');
end
out=struct( ...
 'classification','V524_R2026B_PROSPECTIVE_NEW_X_ORIGINAL_FIRSTBLIND_MICROKERNEL', ...
 'V12','SEALED','NOT_new_firstblind',true, ...
 'new_X_original_firstblind_diagnostic',true,'source_original_only_reads_Rust_values',false, ...
 'input_sha256','9aa8174362012a04b9d4c2ea1f6b4320ee2dc04271f7852a2c2c165e1f934bd1', ...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'case_count',96,'repetitions',2, ...
 'widths',widths,'variants',{cellstr(variants)},'layouts',{cellstr(layouts)}, ...
 'padding_n48',[0 2 3 7],'padding_n65',[0 1 2 7], ...
 'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
