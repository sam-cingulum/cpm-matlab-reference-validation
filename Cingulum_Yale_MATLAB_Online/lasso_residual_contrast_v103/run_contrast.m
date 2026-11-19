function run_contrast
assert(contains(version,'(R2026b) Update 1')); maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows={};
    for j=1:numel(raw)
        q=raw(j);X=reshape(hex2num(char(q.x)),q.n,q.m);y=hex2num(char(q.y));
        for cap=[1 2 3 7]
            [b,f]=lasso(X,y,'UseCovariance',false,'Standardize',false,'Alpha',q.alpha,'Lambda',q.penalty,'MaxIter',cap);
            rows{end+1}=struct('id',sprintf('%s_c%d',q.id,cap),'b',{bits(b)},'ic',num2hex(f.Intercept),'mse',num2hex(f.MSE));
        end
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
