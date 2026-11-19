function run_steps
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
cases=jsondecode(fileread('input.json'));
for rep=1:2
    rows={};
    for k=1:numel(cases)
        q=cases(k);X=reshape(hex2num(char(q.x)),q.n,q.m);y=hex2num(char(q.y));
        for standard=q.standard
            for length=1
                for cap=[1:q.last 100000]
                    args={'Alpha',q.alpha,'Standardize',logical(standard),'Lambda',q.grid(:)','MaxIter',cap};
                    [b,info]=lasso(X,y,args{:});
                    covar=forced(X,y,args,true);resid=forced(X,y,args,false);
                    rows{end+1}=struct('id',sprintf('%s_s%d_l%d_c%d',q.id,standard,length,cap), ...
                        'b',{bits(b)},'ic',{bits(info.Intercept)},'mse',{bits(info.MSE)}, ...
                        'covariance',covar,'residual',resid);
                end
            end
        end
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function f=forced(X,y,args,use)
try
    [b,info]=lasso(X,y,args{:},'UseCovariance',use);
    f=struct('returned',true,'b',{bits(b)},'ic',{bits(info.Intercept)},'mse',{bits(info.MSE)});
catch e
    f=struct('returned',false,'error_id',e.identifier,'error_message',e.message);
end
end
function b=bits(x)
b=cellstr(num2hex(x(:)));
end
