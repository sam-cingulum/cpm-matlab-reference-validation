function run_hotelling
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','oop','HotellingT2');addpath(base);
assert(strcmp(which('T2Hot2ihe'),fullfile(base,'T2Hot2ihe.m')));
mex('-R2018a','inverse_probe.c','-lmwlapack');
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows={};
    for j=1:numel(raw)
        q=raw(j);a=q.n1;b=q.n2;X=reshape(hex2num(char(q.x)),a+b,q.width);
        row=struct('id',q.id);
        lastwarn('','');
        try
            original=T2Hot2ihe(X,a,b,.05);[msg,wid]=lastwarn;
            A=X(1:a,:);B=X(a+1:end,:);S=cov(A);T=cov(B);
            mu=mean(A);nu=mean(B);d=mu-nu;C=S/a+T/b;I=inv(C);z=d*I;t=z*d';pc=chi2cdf(t,q.width);
            assert(isequal(original,1-pc));
            row.p=num2hex(original);row.means=bits([mu;nu]);row.cov=bits(cat(3,S,T));row.scaled=bits(C);
            row.inverse=bits(I);row.projected=bits(z);row.t2=num2hex(t);row.cdf=num2hex(pc);
            shape=q.width/2;arg=t/2;
            row.gamma_control=struct('shape',num2hex(shape),'arg',num2hex(arg),...
                'lower',num2hex(gammainc(arg,shape,'lower')),'upper',num2hex(gammainc(arg,shape,'upper')),...
                'scaled_lower',num2hex(gammainc(arg,shape,'scaledlower')),'scaled_upper',num2hex(gammainc(arg,shape,'scaledupper')));
            [sy,lu,ch,packed,perm]=inverse_probe(C);
            row.inverse_control=struct('symmetric',{bits(sy)},'lu',{bits(lu)},'cholesky',{bits(ch)},...
                'packed',{bits(packed)},'pivots',{bits(perm)});
            row.warning_id=wid;row.warning_message=msg;row.returned=true;
        catch e
            row=struct('id',q.id,'returned',false,'error_id',e.identifier,'error_message',e.message);
        end
        rows{end+1}=row;
    end
    out.repetitions(rep).rows=rows;
    % Observe the same arguments at adjacent shapes, including both sides
    % of x=1 and x=a, so the gamma recurrence can be checked directly.
    args=unique([logspace(-3,2,81),.5,1,1.5,2,2.5,3,4,8,16,32]);
    for v=[.5,1,1.5,2,2.5,3]
        args=[args,v-eps(v),v+eps(v)];
    end
    args=unique(args); ladder=cell(numel(args),1);
    for j=1:numel(args)
        arg=args(j);shapes=.5:.5:3;
        lo=gammainc(arg,shapes,'lower');up=gammainc(arg,shapes,'upper');
        sl=gammainc(arg,shapes,'scaledlower');su=gammainc(arg,shapes,'scaledupper');
        lx=erfcx(sqrt(arg));
        ladder{j}=struct('x',num2hex(arg),'lower',{bits(lo)},'upper',{bits(up)},...
            'scaled_lower',{bits(sl)},'scaled_upper',{bits(su)},'erfcx',num2hex(lx),...
            'erfc',num2hex(erfc(sqrt(arg))));
    end
    out.repetitions(rep).gamma_ladder=ladder;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(x)
b=cellstr(num2hex(double(x(:))));
end
