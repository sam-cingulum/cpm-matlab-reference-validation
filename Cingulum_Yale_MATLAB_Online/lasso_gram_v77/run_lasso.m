function run_lasso
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);X=reshape(hex2num(char(q.x)),q.n,q.m);y=hex2num(char(q.y));
        mx=mean(X,1);my=mean(y);C=X-mx;yc=y-my;
        sx=std(X,1,1);caps=[1 2 3 7 100000];result=cell(1,10);stages=cell(1,2);
        for standard=0:1
            Z=C;
            if standard,Z=Z./sx;end
            stages{standard+1}=struct('gram',{bits(Z'*Z)},'xy',{bits(Z'*yc)});
            for t=1:numel(caps)
                args={'Alpha',q.alpha,'Lambda',q.penalty,'Standardize',logical(standard)};
                if t<numel(caps),args=[args,{'MaxIter',caps(t)}];end
                [b,info]=lasso(X,y,args{:});
                result{5*standard+t}=struct('standardize',logical(standard),'cap',caps(t), ...
                    'b',{bits(b)},'intercept',num2hex(info.Intercept),'mse',num2hex(info.MSE));
            end
        end
        rows{j}=struct('id',q.id,'stages',{stages},'fits',{result});
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
