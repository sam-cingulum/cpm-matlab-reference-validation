function run_original_v355()
% Original-only SOURCE-DISCLOSED panel-width diagnostic AFTER the V340 FAIL.
% Explicit public [Q,R,P]=qr and Q'*B for w1..16 is a diagnostic.
% It is NOT presumed to be the hidden MATLAB full A\B transformation.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
input_path=fullfile(root,'..','multix_v346_post_v340_disclosed_p9p12_diagonal_r','input.json');
d=jsondecode(fileread(input_path));
assert(strcmp(d.classification,'V346_POST_V340_DISCLOSED_P9P12_DIAGONAL_R_SINGLE_ACTIVE_REFLECTOR_ORIGINAL'));
assert(d.source_disclosed_after_V340 && ~d.source_original_MATLAB_numerical_data_consulted);
assert(strcmp(d.V340_original_first_blind,'IMMUTABLE_FAIL_63871_OF_182784'));
assert(strcmp(d.V332_original_first_blind,'PASS_261120_OF_261120'));
assert(strcmp(d.V336_original_first_blind,'PASS_261120_OF_261120'));
assert(strcmp(d.V12,'SEALED'));
assert(d.case_count==32 && numel(d.cases)==32);
pads=[0 1 7 16];widths=[1 2 4 8 9 10 11 12 13 14 15 16];
rows=struct('id',{},'p',{},'n',{},'mode',{},'rep',{},'pad_results',{});
for rep=1:2
 for ci=1:32
  c=d.cases(ci);p=double(c.p);n=double(c.n);
  assert(ismember(p,[9 10 11 12]) && ismember(n,[19 31 48 65]));
  X0=reshape(hex2num(char(c.a_colmajor_hex)),n,p);
  B0=reshape(hex2num(char(c.b16_colmajor_hex)),n,16);
  assert(all(X0(end,:)==0) && all(B0(end,:)==0));
  assert(all(isfinite(X0(:)))&&all(isfinite(B0(:))));
  assert(isequal(B0(:,1),B0(:,2)));
  pad_results=cell(numel(pads),1);
  for zi=1:numel(pads)
   z=pads(zi);
   X=[X0;zeros(z,p)];B=[B0;zeros(z,16)];
   [Q,R,P]=qr(X,'econ','vector');
   assert(isequal(P,1:p));
   assert(all(all(triu(R,1)==0)));
   assert(all(diag(R)~=0) && all(isfinite(R(:))));
   panels=cell(numel(widths),1);
   for wi=1:numel(widths)
    w=widths(wi);
    Y=Q'*B(:,1:w);
    assert(isequal(size(Y),[p w]) && all(isfinite(Y(:))));
    panels{wi}=struct('width',w,'first_projected_row_bits',{cellstr(num2hex(double(Y(1,:).')))});
   end
   pad_results{zi}=struct('z',z,'panels',{panels},...
    'public_qr_r00_bits',num2hex(double(R(1,1))));
  end
  rows(end+1)=struct('id',c.id,'p',p,'n',n,'mode',c.mode,'rep',rep,...
    'pad_results',{pad_results}); %#ok<AGROW>
 end
end
assert(numel(rows)==64);
for i=1:32
 a=rmfield(rows(i),'rep');b=rmfield(rows(i+32),'rep');
 assert(isequal(a,b),'original explicit public QtB repetitions differ');
end
out=struct(...
 'classification','V355_GENUINE_R2026B_SOURCE_DISCLOSED_POST_V346_PUBLIC_QTB_MATRIX_WIDTH_PANELS',...
 'source_disclosed_after_V340',true,...
 'public_QtB_NOT_hidden_A_backslash_B_transformation',true,...
 'original_V340_firstblind','IMMUTABLE_FAIL_63871_OF_182784',...
 'original_V332_firstblind','PASS_261120_OF_261120',...
 'original_V336_firstblind','PASS_261120_OF_261120',...
 'V12','SEALED',...
 'source_public_X_B_sha256','75560b79e18c770ee24c6676abfe0de3c2f1460d2a4c30940deac075508b4abc',...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'case_count',32,'repetitions',2,...
 'padding',pads,'widths',widths,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(out));
end
