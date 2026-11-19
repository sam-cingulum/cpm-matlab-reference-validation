function run_cca
assert(contains(version,'(R2026b) Update 1')); maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);X=reshape(hex2num(char(q.x)),q.n,2);y=hex2num(char(q.y));
        [A,B,r,U,V,stats]=canoncorr(X,y);
        Xc=X-mean(X,1);yc=y-mean(y);
        [Q,R,p]=qr(Xc,'econ','vector');[Qy,Ry]=qr(yc,0);
        cross=Q'*Qy;[us,s,vs]=svd(cross,'econ');
        a=zeros(2,1);a(p)=(R\us)*sqrt(q.n-1);b=(Ry\vs)*sqrt(q.n-1);
        rows{j}=struct('id',q.id,'pivot',{bits(p)},'qx',{bits(Q)},'rx',{bits([R(1,1) R(1,2) R(2,2)])}, ...
            'qy',{bits(Qy)},'ry',num2hex(Ry),'cross',{bits(cross)},'r',num2hex(r),'weight',{bits(A*sign(B))}, ...
            'by',num2hex(abs(B)),'u',{bits(U*sign(B))},'v',{bits(V*sign(B))},'f',num2hex(stats.F), ...
            'p',num2hex(stats.pF),'controls',struct('weight',{bits(a*sign(b))},'by',num2hex(abs(b)), ...
            'r',num2hex(s),'svd_u',{bits(us)},'svd_v',num2hex(vs),'raw_a',{bits(A)},'raw_b',num2hex(B), ...
            'df1',stats.df1,'df2',stats.df2,'upper',num2hex(fcdf(stats.F,stats.df1,stats.df2,'upper'))));
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
