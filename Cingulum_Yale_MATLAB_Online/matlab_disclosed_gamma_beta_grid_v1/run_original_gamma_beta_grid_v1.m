function run_original_gamma_beta_grid_v1()
% Deliberately disclosed numeric-kernel probe against unmodified R2026b.
% NOT V12, NOT source-unseen, and never a claim of native Rust parity.
assert(exist('OCTAVE_VERSION','builtin')==0,'Genuine MathWorks only');
assert(strcmp(version('-release'),'2026b'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
inp=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(inp.schema,'CINGULUM_R2026B_GAMMA_BETA_SOURCE_DISCLOSED_GRID_V1'));
assert(strcmp(inp.classification,'SOURCE_DISCLOSED_NUMERICAL_KERNEL_PROBE_NOT_SOURCE_UNSEEN'));
assert(numel(inp.gamma)==inp.gamma_count && numel(inp.beta)==inp.beta_count);
grecords=struct('id',{},'rep',{},'x_hex',{},'gammaln_hex',{},...
 'gamma_hex',{},'log_gamma_hex',{},'sqrt_pi_hex',{});
brecords=struct('id',{},'rep',{},'a_hex',{},'b_hex',{},'x_hex',{},...
 'gammaln_a_hex',{},'gammaln_b_hex',{},'gammaln_sum_hex',{},...
 'betaln_hex',{},'betaln_gamma_combo_hex',{},...
 'betainc_lower_hex',{},'betainc_upper_hex',{},...
 'log_x_hex',{},'log1p_negative_x_hex',{},'prefactor_log_hex',{});
for rep=1:2
 for i=1:numel(inp.gamma)
  c=inp.gamma(i);x=hex2num(c.x_hex);assert(isscalar(x) && isfinite(x) && x>0);
  g=gamma(x);
  row=struct();row.id=c.id;row.rep=rep;row.x_hex=num2hex(x);
  row.gammaln_hex=num2hex(gammaln(x));
  row.gamma_hex=num2hex(g);
  row.log_gamma_hex=num2hex(log(g));
  row.sqrt_pi_hex=num2hex(sqrt(pi));
  grecords(end+1)=row; %#ok<AGROW>
 end
 for i=1:numel(inp.beta)
  c=inp.beta(i);
  a=hex2num(c.a_hex);b=hex2num(c.b_hex);x=hex2num(c.x_hex);
  assert(all(isfinite([a b x])) && a>0 && b>0 && x>0 && x<1);
  ga=gammaln(a);gb=gammaln(b);gs=gammaln(a+b);
  lb=betaln(a,b);
  row=struct();row.id=c.id;row.rep=rep;
  row.a_hex=num2hex(a);row.b_hex=num2hex(b);row.x_hex=num2hex(x);
  row.gammaln_a_hex=num2hex(ga);row.gammaln_b_hex=num2hex(gb);
  row.gammaln_sum_hex=num2hex(gs);row.betaln_hex=num2hex(lb);
  row.betaln_gamma_combo_hex=num2hex((ga+gb)-gs);
  row.betainc_lower_hex=num2hex(betainc(x,a,b));
  row.betainc_upper_hex=num2hex(betainc(x,a,b,'upper'));
  row.log_x_hex=num2hex(log(x));
  row.log1p_negative_x_hex=num2hex(log1p(-x));
  row.prefactor_log_hex=num2hex(a*log(x)+b*log1p(-x)-lb);
  brecords(end+1)=row; %#ok<AGROW>
 end
 fprintf('DISCLOSED R2026b gamma/beta full grid rep %d/2 gamma=%d beta=%d\n',...
    rep,inp.gamma_count,inp.beta_count);
end
report=struct();
report.classification='ORIGINAL_MATHWORKS_R2026B_SOURCE_DISCLOSED_GAMMA_BETA_GRID_V1';
report.input_schema=inp.schema;
report.original_unmodified=true;report.release=version('-release');
report.matlab_version=version;report.computer=computer;
report.mkl_cbwr=getenv('MKL_CBWR');
report.max_num_comp_threads=maxNumCompThreads;
report.gamma_count=inp.gamma_count;report.beta_count=inp.beta_count;
report.repetitions=2;report.gamma=grecords;report.beta=brecords;
out=getenv('DISCLOSED_GAMMA_BETA_OUTPUT');assert(~isempty(out));
fd=fopen(fullfile(root,out),'w');assert(fd>0);
closing=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
end
