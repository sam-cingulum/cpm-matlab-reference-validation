function run_find
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','misc');addpath(base);
assert(strcmp(which('find_lambda'),fullfile(base,'find_lambda.m')));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);X=reshape(hex2num(char(q.x)),q.m,q.n);y=hex2num(char(q.y));
        rng(q.seed,'twister');lastwarn('');
        [opt,mse]=find_lambda(X,y,q.grid,q.p,q.k);
        [msg,identifier]=lastwarn;
        rng(q.seed,'twister');idx=crossvalind('Kfold',q.n,q.k);
        grid=sort(q.grid(:),'descend');details=cell(1,numel(grid)*q.k);
        for g=1:numel(grid)
            for k=1:q.k
                held=find(idx==k);train=idx~=k;
                A=X(:,train);yy=y(train);
                [~,p]=corr(A',yy);sel=find(p<=q.p);
                args={'Alpha',1e-9,'Lambda',grid(g)};
                if q.m>=300,args=[args,{'RelTol',1e-3,'MaxIter',100}];end
                [b,info]=lasso(A(sel,:)',yy,args{:});
                pred=X(sel,held)'*b+info.Intercept;
                loss=mean((pred-y(held)).^2);
                assert(isequal(num2hex(loss),num2hex(mse(k,g))));
                details{(g-1)*q.k+k}=struct('selected',{bits(sel-1)},'held',{bits(held-1)}, ...
                    'b',{bits(b)},'ic',num2hex(info.Intercept),'pred',{bits(pred)},'mse',num2hex(loss));
            end
        end
        rows{j}=struct('id',q.id,'labels',{bits(double(idx))},'selected_lambda',num2hex(opt), ...
            'mse',{bits(mse)},'mean',{bits(mean(mse,1))},'se',{bits(std(mse,0,1)/sqrt(q.k))}, ...
            'warning_id',identifier,'warning_message',msg,'details',{details});
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
