function run_original_v315()
% V315 genuine original MATLAB R2026b source-DISCLOSED numerical research.
% INPUT IS INDEPENDENT PURE-RUST RAW QR-R and transformed Qy from public
% synthetic X/B ONLY; it contains NO previous original MATLAB coefficients.
% This is NOT an original-first-blind certificate and cannot overwrite the
% immutable V308 first-blind FAIL 54741/57816.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1); assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
src=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(src.classification,...
 'V315_SOURCE_DISCLOSED_POST_V308_ORIGINAL_R2026B_TRIANGULAR_R_SOLVE_FROM_INDEPENDENT_RUST_QR_QY'));
assert(src.case_count==16 && numel(src.cases)==16);
assert(src.source_disclosed_after_V308);
assert(~src.original_MATLAB_numerical_output_consulted_to_construct_inputs);
assert(strcmp(src.source_independent_Rust_stage_archive_sha256,...
 'a27d1edecca6b8cd1019c361422e71bb304399f2d5939188e17626526d800944'));
assert(strcmp(src.original_first_blind_V308,'IMMUTABLE_FAIL_54741_OF_57816'));
assert(strcmp(src.V284_single_original_first_blind,'PASS_1770_OF_1770'));
assert(strcmp(src.V12,'SEALED'));
widths=[2 3 4 5 6 7 8 9 12 16];
padding=[0 1 7];
assert(isequal(double(src.RHS_widths(:).'),widths));
assert(isequal(double(src.padding(:).'),padding));
rows=struct('id',{},'rep',{},'p',{},'n',{},'family',{},'source_independent_Rust_QR_triangular_stages',{});
for rep=1:2
 for ci=1:16
  c=src.cases(ci);
  p=double(c.p);n=double(c.n);
  assert(ismember(p,[7 8]) && n>p);
  assert(numel(c.pads)==3);
  pads=cell(3,1);
  for pi=1:3
   a=c.pads(pi);
   assert(double(a.padding)==padding(pi));
   R=reshape(hex2num(char(a.source_only_upper_triangular_R_colmajor_hex)),p,p);
   assert(isequal(size(R),[p p]));
   assert(all(isfinite(R(:))) && all(diag(R)~=0));
   assert(isequal(tril(R,-1),zeros(p,p)),'independent pure Rust QR R is not triangular');
   stages=cell(numel(widths),1);
   for wi=1:numel(widths)
    stage=a.rhs_width_panels(wi);
    w=widths(wi);
    assert(double(stage.rhs_width)==w);
    QY=reshape(hex2num(char(stage.source_only_qy_colmajor_hex)),p,w);
    assert(isequal(size(QY),[p w]) && all(isfinite(QY(:))));
    actual=R\QY;
    assert(isequal(size(actual),[p w]) && all(isfinite(actual(:))));
    cols=cell(w,1);
    for j=1:w
     cols{j}=cellstr(num2hex(double(actual(:,j))));
    end
    stages{wi}=struct('rhs_width',w,...
      'source_original_R_backslash_native_Qy_col_hex',{cols});
   end
   pads{pi}=struct('extra_terminal_zero_rows',padding(pi),...
     'rhs_width_panels',{stages});
  end
  rows(end+1)=struct('id',c.id,'rep',rep,'p',p,'n',n,'family',c.family,...
    'source_independent_Rust_QR_triangular_stages',{pads}); %#ok<AGROW>
 end
end
assert(numel(rows)==32);
for k=1:16
 a=rmfield(rows(k),'rep');
 b=rmfield(rows(k+16),'rep');
 assert(isequal(a,b),'original triangular MATLAB execution not reproducible bitwise');
end
output=struct(...
 'classification','V315_GENUINE_R2026B_SOURCE_DISCLOSED_TRIANGULAR_SOLVER_ON_RUST_QR_STAGES',...
 'source_disclosed_after_V308',true,...
 'original_MATLAB_numerical_coefficients_supplied_to_Rust',false,...
 'source_original_run',getenv('GITHUB_RUN_ID'),...
 'release',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'source_original_input_sha256','37c6039168cdbc407c517c04a16ec12edc100f7b6798faebfb7dcc3a647394a5',...
 'original_first_blind_V308','IMMUTABLE_FAIL_54741_OF_57816',...
 'V284_first_blind_solo','PASS_1770_OF_1770',...
 'comprehensive_V12','SEALED',...
 'cases',16,'repetitions',2,'rhs_widths',widths,'padding',padding,'rows',rows);
f=fopen(fullfile(root,'original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(output));
end
