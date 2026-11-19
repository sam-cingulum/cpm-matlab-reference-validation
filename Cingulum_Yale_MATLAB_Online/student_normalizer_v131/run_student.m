function run_student
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
q=jsondecode(fileread('input.json'));
for rep=1:2
  rows=cell(1,numel(q));
  for i=1:numel(q)
    df=q(i).df;t=hex2num(q(i).t);v=t*t;den=df+v;
    if v<df,a=.5;b=df/2;x=v/den;tail='upper';else,a=df/2;b=.5;x=df/den;tail='lower';end
    lower=betainc(x,a,b,'lower');upper=betainc(x,a,b,'upper');
    gb=gammaln(b);ga=gammaln(a);gs=gammaln(a+b);lb=betaln(a,b);
    c=tcdf(-abs(t),df);
    rows{i}=struct('id',q(i).id,'a',num2hex(a),'b',num2hex(b),'x',num2hex(x),'tail',tail,...
      'ga',num2hex(ga),'gb',num2hex(gb),'gs',num2hex(gs),'lb',num2hex(lb),'manual',num2hex(ga+gb-gs),...
      'lower',num2hex(lower),'upper',num2hex(upper),'negative',num2hex(c),'p',num2hex(2*c));
  end
  out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
