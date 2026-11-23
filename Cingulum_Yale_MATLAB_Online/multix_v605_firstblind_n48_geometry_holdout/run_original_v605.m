function run_original_v605()
% Prospective independent genuine R2026b original-firstblind X/B challenge.
% Never reads Rust forecasts or original numerical results.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
cpu=fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));
root=fileparts(mfilename('fullpath'));
source=fullfile(root,'input.json');
s=jsondecode(fileread(source));
assert(strcmp(s.classification,'V605_PROSPECTIVE_R2026B_ORIGINAL_ONLY_NEW_X_B'));
assert(s.source_only && ~s.NOT_new_original_firstblind && s.new_source_firstblind_candidate && strcmp(s.V12,'SEALED'));
assert(~s.original_MATLAB_numerical_outputs_read && ~s.independent_Rust_outputs_read);
assert(numel(s.cases)==96 && numel(s.matrices)==8 && double(s.seed)==202611240605);
assert(all(strcmp(string({s.cases.layout}),'repeated')));
matIds=string({s.matrices.id});
assert(numel(unique(matIds))==8);
widths=[1,2,11,12,13,16,17,20,23,24,25,28,32];
maxwidth=32;
% 1-based probes deliberately sample both sides of 12/24 column boundaries.
singleColumns=[1,2,11,12,13,16,17,20,23,24,25,28,32];
layouts=["repeated","signed_power2"];
padding48=[0,2,3,7];padding65=[0,1,2,7];
rows=struct('id',{},'rep',{},'n',{},'p',{},'layouts',{});
for rep=1:2
 for ci=1:96
  c=s.cases(ci);mid=find(matIds==string(c.matrix_id));
  assert(isscalar(mid));
  m=s.matrices(mid);n=double(m.n);p=double(m.p);
  assert(ismember(n,[48 65]) && ismember(p,[9 10 11 12]));
  X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  b=reshape(hex2num(char(c.b_colmajor_hex)),n,1);
  assert(all(isfinite(X(:))) && all(isfinite(b)) && all(X(end,:)==0) && b(end)==0);
  zvec=padding48;
  if n==65;zvec=padding65;end
  layoutRecords=cell(numel(layouts),1);
  for li=1:numel(layouts)
   layout=layouts(li);
   Y=repmat(b,1,maxwidth);
   if layout=="signed_power2"
    for j=1:maxwidth
     scale=pow2(1,mod(j-1,5)-2);
     if mod(j,2)==0;scale=-scale;end
     Y(:,j)=b*scale;
    end
   end
   assert(all(isfinite(Y(:))));
   pads=cell(numel(zvec),1);
   for zi=1:numel(zvec)
    z=zvec(zi);
    Xp=[X;zeros(z,p)];Yp=[Y;zeros(z,maxwidth)];
    [Q,R,P]=qr(Xp,'econ','vector');
    assert(isequal(double(P(:).'),1:p));
    D=decomposition(Xp,'qr');
    % Original single-column solve against the SAME cached factorization.
    singles=cell(numel(singleColumns),1);
    for si=1:numel(singleColumns)
     j=singleColumns(si);
     one=D\Yp(:,j);
     assert(isequal(size(one),[p,1]));
     singles{si}=struct('one_based_j',j,'first_two_hex',{cellstr(num2hex(double(one(1:2))))});
    end
    panels=cell(numel(widths),1);
    for wi=1:numel(widths)
     w=widths(wi);Z=Yp(:,1:w);
     hidden=Xp\Z;
     cached=D\Z;
     explicit=R\(Q'*Z);
     assert(all(isfinite(hidden(:))) && all(isfinite(cached(:))) && all(isfinite(explicit(:))));
     assert(isequal(size(hidden),[p w]) && isequal(size(cached),[p w]));
     cols=cell(w,1);
     for j=1:w
      cols{j}=struct( ...
       'hidden_first2_hex',{cellstr(num2hex(double(hidden(1:2,j))))}, ...
       'cached_decomposition_first2_hex',{cellstr(num2hex(double(cached(1:2,j))))}, ...
       'explicit_qr_first2_hex',{cellstr(num2hex(double(explicit(1:2,j))))});
     end
     panels{wi}=struct('w',w,'columns',{cols});
    end
    pads{zi}=struct('z',z,'single_cached_decomposition_columns',{singles},'panels',{panels});
   end
   layoutRecords{li}=struct('layout',char(layout),'pads',{pads});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'n',n,'p',p,'layouts',{layoutRecords}); %#ok<AGROW>
 end
end
assert(numel(rows)==192);
for i=1:96
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+96),'rep');
 assert(isequal(a,b),'genuine MATLAB repeated original raw-stage bits not exact');
end
out=struct( ...
 'classification','V605_R2026B_NEW_X_B_GENUINE_ORIGINAL_FIRSTBLIND_QR_PANEL_WIDTH32', ...
 'NOT_new_firstblind',false,'V12','SEALED', ...
 'source_original_only_reads_Rust_values',false, ...
 'source_V605_input_SHA256','76ba3aafc7e0e88ef64883566c080f28f55e6299dbb73f698b8b26121e2d5ff6', ...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'case_count',96,'repetitions',2, ...
 'widths',widths,'single_onebased_columns',singleColumns, ...
 'padding_n48',padding48,'padding_n65',padding65, ...
 'layouts',{cellstr(layouts)}, ...
 'panels_per_repetition',96*4*numel(layouts)*numel(widths), ...
 'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
