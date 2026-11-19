function run_empty
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
for rep=1:2
    rows=cell(1,6);
    for j=1:6
        n=18+3*j;y=(1:n)'/7;
        if j<=3,X=zeros(n,0);else,X=ones(n,1);end
        lastwarn('');
        try
            [b,info]=lasso(X,y,'Alpha',1e-9,'Lambda',.125);
            [wm,wi]=lastwarn;
            rows{j}=struct('n',n,'p',size(X,2),'returned',true,'b_size',size(b), ...
                'b',{cellstr(num2hex(b(:)))},'intercept',num2hex(info.Intercept),'mse',num2hex(info.MSE), ...
                'warning_id',wi,'warning_message',wm);
        catch e
            rows{j}=struct('n',n,'p',size(X,2),'returned',false,'error_id',e.identifier,'error_message',e.message);
        end
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
