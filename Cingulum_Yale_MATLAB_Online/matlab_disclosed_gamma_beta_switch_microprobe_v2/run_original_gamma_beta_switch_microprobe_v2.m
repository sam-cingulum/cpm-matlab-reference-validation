function run_original_gamma_beta_switch_microprobe_v2()
% Explicitly SOURCE-DISCLOSED branch/recurrence microprobe, NOT V12.
% Original built-in MathWorks functions are used UNMODIFIED.
assert(exist('OCTAVE_VERSION','builtin')==0,'Genuine MathWorks MATLAB only');
assert(strcmp(version('-release'),'2026b'),'Original MATLAB R2026b required');
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'),'MKL compatibility gate');
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
inp=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(inp.schema,'CINGULUM_R2026B_GAMMA_BETA_BRANCH_MICROPROBE_V2_SOURCE_DISCLOSED'));
assert(strcmp(inp.classification,'SOURCE_DISCLOSED_NUMERICAL_BRANCH_MICROPROBE_NOT_SOURCE_UNSEEN'));
assert(strcmp(inp.source_unseen_V12,'NOT_GENERATED'));
assert(inp.original_MATLAB_numeric_data_supplied==false);
assert(numel(inp.gamma)==inp.gamma_count && numel(inp.beta)==inp.beta_count && numel(inp.student)==inp.student_count);

% Explicitly fixed raw-binary64 field schemas. No output rows are suppressed.
grows=struct('id',{},'rep',{},'x_hex',{},...
 'gammaln_hex',{},'gammaln_xplus1_hex',{},...
 'gammaln_recurrence_hex',{},'gamma_hex',{},'log_gamma_hex',{});
brows=struct('id',{},'rep',{},'a_hex',{},'b_hex',{},'x_hex',{},...
 'ga_hex',{},'gb_hex',{},'gsum_hex',{},...
 'betaln_hex',{},'composed_betaln_hex',{},...
 'lower_hex',{},'upper_hex',{},...
 'log_x_hex',{},'log1p_negative_x_hex',{},...
 'log_prefactor_hex',{},'log_prefactor_alt_hex',{});
trows=struct('id',{},'rep',{},'nu_hex',{},'t_hex',{},...
 't_abs_hex',{},'t2_hex',{},'den_hex',{},'u_hex',{},'x_hex',{},...
 'tcdf_negative_hex',{},'two_tcdf_hex',{},...
 'betainc_lower_hex',{},'betainc_upper_hex',{},'piecewise_tail_hex',{});
for rep=1:2
  for i=1:numel(inp.gamma)
    c=inp.gamma(i);x=hex2num(c.x_hex);
    assert(isfinite(x) && x>0 && x<=61);
    gl=gammaln(x);
    r=struct();r.id=c.id;r.rep=rep;r.x_hex=num2hex(x);
    r.gammaln_hex=num2hex(gl);
    r.gammaln_xplus1_hex=num2hex(gammaln(x+1));
    r.gammaln_recurrence_hex=num2hex(gl+log(x));
    g=gamma(x);
    r.gamma_hex=num2hex(g);r.log_gamma_hex=num2hex(log(g));
    grows(end+1)=r; %#ok<AGROW>
  end
  for i=1:numel(inp.beta)
    c=inp.beta(i);
    a=hex2num(c.a_hex);b=hex2num(c.b_hex);x=hex2num(c.x_hex);
    assert(all(isfinite([a b x])) && a>0 && b>0 && x>0 && x<1);
    ga=gammaln(a);gb=gammaln(b);gs=gammaln(a+b);
    lb=betaln(a,b);
    r=struct();r.id=c.id;r.rep=rep;r.a_hex=num2hex(a);
    r.b_hex=num2hex(b);r.x_hex=num2hex(x);
    r.ga_hex=num2hex(ga);r.gb_hex=num2hex(gb);r.gsum_hex=num2hex(gs);
    r.betaln_hex=num2hex(lb);r.composed_betaln_hex=num2hex((ga+gb)-gs);
    r.lower_hex=num2hex(betainc(x,a,b));
    r.upper_hex=num2hex(betainc(x,a,b,'upper'));
    r.log_x_hex=num2hex(log(x));r.log1p_negative_x_hex=num2hex(log1p(-x));
    r.log_prefactor_hex=num2hex(a*log(x)+b*log1p(-x)-lb);
    r.log_prefactor_alt_hex=num2hex(-lb+a*log(x)+b*log(1-x));
    brows(end+1)=r; %#ok<AGROW>
  end
  for i=1:numel(inp.student)
    c=inp.student(i);nu=hex2num(c.nu_hex);t=hex2num(c.t_hex);
    assert(isfinite(nu) && nu>0 && isfinite(t));
    z=abs(t);t2=z*z;den=nu+t2;
    u=t2/den;x=nu/den;
    direct=tcdf(-z,nu);
    lo=betainc(x,nu/2,0.5);
    hi=betainc(u,0.5,nu/2,'upper');
    selected=lo;
    if t2<nu
      selected=hi;
    end
    r=struct();r.id=c.id;r.rep=rep;
    r.nu_hex=num2hex(nu);r.t_hex=num2hex(t);
    r.t_abs_hex=num2hex(z);r.t2_hex=num2hex(t2);
    r.den_hex=num2hex(den);r.u_hex=num2hex(u);r.x_hex=num2hex(x);
    r.tcdf_negative_hex=num2hex(direct);
    r.two_tcdf_hex=num2hex(2*direct);
    r.betainc_lower_hex=num2hex(lo);
    r.betainc_upper_hex=num2hex(hi);
    r.piecewise_tail_hex=num2hex(selected);
    trows(end+1)=r; %#ok<AGROW>
  end
  fprintf('DISCLOSED gamma/beta switch V2 MATLAB source rep=%d/2 gamma=%d beta=%d student=%d\n',...
    rep,inp.gamma_count,inp.beta_count,inp.student_count);
end
out=struct();
out.classification='ORIGINAL_MATHWORKS_R2026B_GAMMA_BETA_SWITCH_MICROPROBE_V2_SOURCE_DISCLOSED';
out.source_unseen_V12='NOT_GENERATED';
out.input_schema=inp.schema;out.original_unmodified=true;
out.release=version('-release');out.matlab_version=version;
out.computer=computer;out.mkl_cbwr=getenv('MKL_CBWR');
out.max_num_comp_threads=maxNumCompThreads;
out.repetitions=2;
out.gamma_count=inp.gamma_count;out.beta_count=inp.beta_count;out.student_count=inp.student_count;
out.gamma=grows;out.beta=brows;out.student=trows;
destination=getenv('DISCLOSED_SWITCH_V2_OUTPUT');
assert(~isempty(destination),'Output file is required');
fileId=fopen(fullfile(root,destination),'w');assert(fileId>0);
onClose=onCleanup(@()fclose(fileId));
fprintf(fileId,'%s\n',jsonencode(out));
end
