function run_original_v641()
% Genuine original-only prospective V641 Q'*B physical row-length test.
% The runner reads new source-only X/B and never reads Rust predictions.
assert(exist('OCTAVE_VERSION','builtin') == 0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
cpu=fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));
root=fileparts(mfilename('fullpath'));
s=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(s.classification,'V641_PROSPECTIVE_ORIGINAL_UNSEEN_PUBLIC_QTB_ROW_LENGTH'));
assert(s.source_only && strcmp(s.V12,'SEALED'));
assert(~s.original_MATLAB_numerical_outputs_read && ~s.independent_Rust_outputs_read);
assert(double(s.seed)==202611246411);
assert(numel(s.matrices)==5 && numel(s.cases)==25);
widths=[1,2,3,5,7,9,11,12,13,14,15,16,17,19,20,21,23,24,25,26,27,28,29,31,32];
assert(isequal(double(s.widths(:).'),widths));
layouts=["repeated","signed_power2"];
rows=struct('id',{},'rep',{},'n',{},'p',{},'z',{},'r_row0',{},'r_row1',{}, ...
            'q_col0',{},'q_col1',{},'probes',{});
for rep=1:2
 for mi=1:numel(s.matrices)
  m=s.matrices(mi);id=char(m.id);n=double(m.n);p=double(m.p);
  assert(n>p+1 && numel(m.padding)==2);
  X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  for z=double(m.padding(:).')
   Xp=[X;zeros(z,p)];
   [Q,R,P]=qr(Xp,'econ','vector');
   assert(isequal(double(P(:).'),1:p));
   D=decomposition(Xp,'qr');
   probes=cell(5,1);
   for probe=0:4
    cid=sprintf('%s_probe_%02d',id,probe);
    ci=find(string({s.cases.id})==string(cid));
    assert(isscalar(ci));
    b=reshape(hex2num(char(s.cases(ci).b_colmajor_hex)),n,1);
    br=[b;zeros(z,1)];
    layoutRows=cell(2,1);
    for li=1:2
     layout=layouts(li);
     Y=repmat(br,1,32);
     if layout=="signed_power2"
      for j=1:32
       scale=pow2(1,mod(j-1,5)-2);
       if mod(j,2)==0;scale=-scale;end
       Y(:,j)=br*scale;
      end
     end
     panels=cell(numel(widths),1);
     for wi=1:numel(widths)
      w=widths(wi);Z=Y(:,1:w);
      projected=Q'*Z;
      explicit=R\projected;
      hidden=Xp\Z;
      cached=D\Z;
      assert(isequal(size(projected),[p,w]));
      assert(isequal(size(hidden),[p,w]));
      assert(isequal(hidden(1:2,:),cached(1:2,:)));
      columns=cell(w,1);
      for j=1:w
       columns{j}=struct('column',j, ...
         'public_qtb_first2_hex',{cellstr(num2hex(double(projected(1:2,j))))}, ...
         'explicit_first2_hex',{cellstr(num2hex(double(explicit(1:2,j))))}, ...
         'hidden_first2_hex',{cellstr(num2hex(double(hidden(1:2,j))))});
      end
      panels{wi}=struct('w',w,'columns',{columns});
     end
     layoutRows{li}=struct('layout',char(layout),'panels',{panels});
    end
    probes{probe+1}=struct('case_id',cid,'layouts',{layoutRows});
   end
   rows(end+1)=struct('id',id,'rep',rep,'n',n,'p',p,'z',z, ...
      'r_row0',{cellstr(num2hex(double(R(1,:).')))}, ...
      'r_row1',{cellstr(num2hex(double(R(2,:).')))}, ...
      'q_col0',{cellstr(num2hex(double(Q(:,1))))}, ...
      'q_col1',{cellstr(num2hex(double(Q(:,2))))}, ...
      'probes',{probes}); %#ok<AGROW>
  end
 end
end
assert(numel(rows)==20);
for i=1:10
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+10),'rep');
 assert(isequal(a,b),'V641 original repetitions differ');
end
out=struct('classification','V641_ORIGINAL_R2026B_UPDATE1_PUBLIC_QTB_FIRSTBLIND', ...
 'V12','SEALED','source_unseen_original_firstblind',true, ...
 'original_source_reads_Rust_values',false, ...
 'input_SHA256','0fdf41fc636dd99cdd00adda5b46b7764a1adcfef2ece2b2f42d5105cee75620', ...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'repetitions',2, ...
 'widths',widths,'rows',rows);
f=fopen(fullfile(root,'original_v641.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
