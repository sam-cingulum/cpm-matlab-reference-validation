function run_deviance
addpath('../hotelling_two_v121'); run_hotelling;
x=jsondecode(fileread('gamma.json'));
for k=1:2
    rows=cell(1,numel(x));
    for j=1:numel(x)
        v=hex2num(x{j}); lo=gammainc(v,1); up=gammainc(v,1,'upper');
        if v<=1, scaled=gammainc(v,1,'scaledlower'); else, scaled=gammainc(v,1,'scaledupper'); end
        chi=chi2cdf(v+v,2);
        rows{j}=struct('id',x{j},'chi',num2hex(chi),'lower',num2hex(lo),'upper',num2hex(up), ...
            'complement',num2hex(1-chi),'scaled_direct',num2hex(scaled));
    end
    out.repetitions(k).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');out.release=version;
fid=fopen('gamma_original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
