function run_lasso_cv
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
cases=jsondecode(fileread('input.json'));
for rep=1:2
    rows={};
    for j=1:numel(cases)
        q=cases(j);n=q.n;X=reshape(hex2num(char(q.x)),n,q.m);y=hex2num(char(q.y));args={'Alpha',q.alpha};
        rng(q.seed,'twister');[b,fit]=lasso(X,y,args{:},'CV',10);next=rand(1,4);
        rng(q.seed,'twister');part=cvpartition(n,'KFold',10);afterpart=rand(1,4);
        rng(q.seed,'twister');p=cvpartition(n,'KFold',10);[b2,info]=lasso(X,y,args{:},'CV',p);next2=rand(1,4);
        [b3,nocv]=lasso(X,y,args{:});
        labels=zeros(n,1);loss=zeros(10,numel(fit.Lambda));sizes=zeros(10,1);
        for k=1:10
            tr=training(part,k);testidx=test(part,k);labels(testidx)=k;sizes(k)=sum(testidx);
            [c,f]=lasso(X(tr,:),y(tr),args{:},'Lambda',fit.Lambda);
            predictions=X(testidx,:)*c+f.Intercept;
            loss(k,:)=mean((predictions-y(testidx)).^2,1);
        end
        rows{end+1}=struct('id',q.id,'lambda',{bits(fit.Lambda)},'labels',{bits(labels)}, ...
            'next',{bits(next)},'next_explicit',{bits(next2)},'next_partition',{bits(afterpart)}, ...
            'actual',summary(b,fit),'explicit',summary(b2,info),'nocv_b',{bits(b3)},'nocv_lambda',{bits(nocv.Lambda)}, ...
            'nocv_ic',{bits(nocv.Intercept)},'loss',{bits(loss)},'sizes',{bits(sizes)});
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function s=summary(b,fit)
s=struct('b',{bits(b)},'ic',{bits(fit.Intercept)},'mse',{bits(fit.MSE)},'se',{bits(fit.SE)},'lambda',{bits(fit.Lambda)}, ...
    'idx_min',fit.IndexMinMSE,'idx_1se',fit.Index1SE,'shape',size(b));
end
function b=bits(x)
b=cellstr(num2hex(double(x(:))));
end
