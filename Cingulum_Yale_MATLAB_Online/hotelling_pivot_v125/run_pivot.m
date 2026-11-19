function run_pivot
addpath('../hotelling_two_v121');
run_hotelling;
out=jsondecode(fileread('original.json'));
% Keep the V121 writer's JSON array shapes intact, including one-element cells.
x=hex2num(char(jsondecode(fileread('gamma.json'))));
for k=1:2
    q=zeros(numel(x),9);
    for j=1:numel(x)
        v=x(j);
        q(j,:)=[chi2cdf(2*v,2),gammainc(v,1),gammainc(v,1,'upper'),...
            gammainc(v,1,'scaledlower'),gammainc(v,1,'scaledupper'),...
            exp(-v),-expm1(-v),gamcdf(2*v,1,2),chi2cdf(2*v,2,'upper')];
    end
    probe.repetitions(k).columns=reshape(cellstr(num2hex(q(:))),size(q));
end
assert(isequal(probe.repetitions(1),probe.repetitions(2)));
probe.commit=out.commit;probe.run=out.run;probe.release=out.release;
fid=fopen('gamma_original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(probe));assert(fclose(fid)==0);
end
