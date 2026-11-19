function run_gamma
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
args=jsondecode(fileread('input.json'));x=hex2num(char(args));
for rep=1:2
    rows=cell(1,numel(x));
    for i=1:numel(x)
        t=x(i);l=log(t);z=l-t;d=exp(z);
        lo=gammainc(t,1);up=gammainc(t,1,'upper');sl=gammainc(t,1,'scaledlower');su=gammainc(t,1,'scaledupper');
        rows{i}=struct('x',args{i},'chi',num2hex(chi2cdf(t+t,2)),'complement',num2hex(1-chi2cdf(t+t,2)),...
            'log',num2hex(l),'logscale',num2hex(z),'scale',num2hex(d),'lower',num2hex(lo),'upper',num2hex(up),...
            'scaled_lower',num2hex(sl),'scaled_upper',num2hex(su),'lower_product',num2hex(sl*d),...
            'upper_product',num2hex(su*d),'exp',num2hex(exp(-t)),'expm1',num2hex(-expm1(-t)));
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
