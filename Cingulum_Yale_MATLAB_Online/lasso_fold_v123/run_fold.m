function run_fold
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
q=jsondecode(fileread('input.json'));X=reshape(hex2num(char(q.x)),q.n,q.m);y=hex2num(char(q.y));
for rep=1:2
    [~,whole]=lasso(X,y,'Alpha',q.alpha);grid=whole.Lambda;
    rng(q.seed,'twister');part=cvpartition(q.n,'KFold',10);rows={};
    for k=[7 8 9]
        tr=training(part,k);testidx=test(part,k);
        caps=100000;if k==8,caps=[7 15 31 63 127 255 511 100000];end
        for cap=caps
            [b,fit]=lasso(X(tr,:),y(tr),'Alpha',q.alpha,'Lambda',grid,'MaxIter',cap);
            z=X(testidx,:)*b+fit.Intercept;
            rows{end+1}=struct('id',sprintf('fold%d_cap%d',k,cap),'lambda',{bits(grid)},'b',{bits(b)}, ...
                'ic',{bits(fit.Intercept)},'mse',{bits(fit.MSE)},'held',{bits(find(testidx))},'y',{bits(z)}, ...
                'loss',{bits(mean((z-y(testidx)).^2,1))});
        end
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(x)
b=cellstr(num2hex(x(:)));
end
