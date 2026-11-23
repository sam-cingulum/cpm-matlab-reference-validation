function run_disclosed_v630()
% Genuine R2026b Update1 source-disclosed public QR and Q'*Y intermediate trace.
% This experiment uses the already revealed V624 X/B archive. No Rust outputs.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
cpu=fileread('/proc/cpuinfo');
assert(contains(cpu,'AMD EPYC 7763') || contains(cpu,'AMD EPYC 9V45'));
root=fileparts(mfilename('fullpath'));
source=fullfile(root,'../multix_v624_firstblind_n65_cross_disagreement_holdout/input.json');
s=jsondecode(fileread(source));
assert(strcmp(s.classification,'V624_PROSPECTIVE_R2026B_ORIGINAL_ONLY_NEW_X_B'));
assert(s.source_only && strcmp(s.V12,'SEALED'));
assert(double(s.seed)==202611246203);
widths=[1,12,13,24,25,32];
layouts=["repeated","signed_power2"];
rows=struct('id',{},'rep',{},'n',{},'p',{},'z',{},'r_row0',{},'r_row1',{}, ...
            'q_col0',{},'q_col1',{},'probes',{});
for rep=1:2
 for p=[9,10]
  id=sprintf('v624_new_two_reflector_n65_p%d',p);
  mid=find(string({s.matrices.id})==string(id));
  assert(isscalar(mid));
  m=s.matrices(mid);n=double(m.n);
  assert(n==65 && double(m.p)==p);
  X=reshape(hex2num(char(m.a_colmajor_hex)),n,p);
  for z=[2,7]
   Xp=[X;zeros(z,p)];
   [Q,R,P]=qr(Xp,'econ','vector');
   assert(isequal(double(P(:).'),1:p));
   D=decomposition(Xp,'qr');
   probeRows=cell(3,1);
   for probe=0:2
    cid=sprintf('%s_new_probe_%02d',id,probe);
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
      public_qtz=Q'*Z;
      public_explicit=R\public_qtz;
      hidden=Xp\Z;
      cached=D\Z;
      assert(isequal(size(public_qtz),[p,w]));
      assert(isequal(size(hidden),[p,w]));
      assert(isequal(hidden(1:2,:),cached(1:2,:)));
      cols=cell(w,1);
      for j=1:w
       cols{j}=struct('column',j, ...
         'public_qtz_first2_hex',{cellstr(num2hex(double(public_qtz(1:2,j))))}, ...
         'public_explicit_first2_hex',{cellstr(num2hex(double(public_explicit(1:2,j))))}, ...
         'hidden_first2_hex',{cellstr(num2hex(double(hidden(1:2,j))))});
      end
      panels{wi}=struct('w',w,'columns',{cols});
     end
     layoutRows{li}=struct('layout',char(layout),'panels',{panels});
    end
    probeRows{probe+1}=struct('case_id',cid,'layouts',{layoutRows});
   end
   rows(end+1)=struct('id',id,'rep',rep,'n',n,'p',p,'z',z, ...
      'r_row0',{cellstr(num2hex(double(R(1,:).')))}, ...
      'r_row1',{cellstr(num2hex(double(R(2,:).')))}, ...
      'q_col0',{cellstr(num2hex(double(Q(:,1))))}, ...
      'q_col1',{cellstr(num2hex(double(Q(:,2))))}, ...
      'probes',{probeRows}); %#ok<AGROW>
  end
 end
end
assert(numel(rows)==8);
for i=1:4
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+4),'rep');
 assert(isequal(a,b),'source-disclosed original QR and Q-transpose stages drift');
end
out=struct('classification','V630_R2026B_SOURCE_DISCLOSED_PUBLIC_QR_INTERMEDIATE', ...
 'V12','SEALED','NOT_new_firstblind',true, ...
 'source_original_only_reads_Rust_values',false, ...
 'source_V624_input_SHA256','77fdca9866b32179c310ee3e2c92982058a34fd4fc8fd29b7a30cfd625d8b18b', ...
 'release',version,'original_run_id',getenv('GITHUB_RUN_ID'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'repetitions',2, ...
 'widths',widths,'rows',rows);
f=fopen(fullfile(root,'original_v630.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
