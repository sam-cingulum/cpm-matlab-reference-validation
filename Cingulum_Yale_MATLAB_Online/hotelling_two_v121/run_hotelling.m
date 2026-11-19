function run_hotelling
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','oop','HotellingT2');addpath(base);
assert(strcmp(which('T2Hot2ihe'),fullfile(base,'T2Hot2ihe.m')));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows={};
    for j=1:numel(raw)
        q=raw(j);a=q.n1;b=q.n2;X=reshape(hex2num(char(q.x)),a+b,2);
        row=struct('id',q.id);
        lastwarn('','');
        try
            original=T2Hot2ihe(X,a,b,.05);[msg,wid]=lastwarn;
            A=X(1:a,:);B=X(a+1:end,:);S=cov(A);T=cov(B);
            mu=mean(A);nu=mean(B);d=mu-nu;C=S/a+T/b;I=inv(C);z=d*I;t=z*d';pc=chi2cdf(t,2);
            assert(isequal(original,1-pc));
            row.p=num2hex(original);row.means=bits([mu;nu]);row.cov=bits(cat(3,S,T));row.scaled=bits(C);
            row.inverse=bits(I);row.projected=bits(z);row.t2=num2hex(t);row.cdf=num2hex(pc);
            row.warning_id=wid;row.warning_message=msg;row.returned=true;
        catch e
            row=struct('id',q.id,'returned',false,'error_id',e.identifier,'error_message',e.message);
        end
        rows{end+1}=row;
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(x)
b=cellstr(num2hex(double(x(:))));
end
