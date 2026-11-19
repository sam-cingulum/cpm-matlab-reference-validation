function run_lasso
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);X=reshape(hex2num(char(q.x)),q.n,q.m);y=hex2num(char(q.y));
        mx=mean(X,1);my=mean(y);C=X-mx;yc=y-my;
        sx=std(X,1,1);Z=C./sx;G=Z'*Z;cxy=Z'*yc;
        result=cell(1,3);
        for standard=0:1
            [b,info]=lasso(X,y,'Alpha',q.alpha,'Lambda',q.penalty,'Standardize',logical(standard),'MaxIter',1);
            result{standard+1}=struct('b',{bits(b)},'intercept',num2hex(info.Intercept),'mse',num2hex(info.MSE));
        end
        [b,info]=lasso(X,y,'Alpha',q.alpha,'Lambda',q.penalty);
        result{3}=struct('b',{bits(b)},'intercept',num2hex(info.Intercept),'mse',num2hex(info.MSE));
        rows{j}=struct('id',q.id,'mx',{bits(mx)},'my',num2hex(my),'sx',{bits(sx)}, ...
            'z',{bits(Z)},'gram',{bits(G)},'xy',{bits(cxy)},'fits',{result});
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(x)
b=cellstr(num2hex(x(:)));
end
