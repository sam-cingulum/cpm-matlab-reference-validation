function run_path
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
cases=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(cases)*2);j=0;
    for k=1:numel(cases)
        q=cases(k);X=reshape(hex2num(char(q.x)),q.n,q.m);y=hex2num(char(q.y));
        for standard=0:1
            j=j+1;args={'Alpha',q.alpha,'Standardize',logical(standard)};lastwarn('','');
            [b,info]=lasso(X,y,'Lambda',q.penalties,args{:});[msg,wid]=lastwarn;
            single_b=zeros(size(b));single_ic=zeros(size(info.Intercept));single_mse=single_ic;
            for li=1:numel(info.Lambda)
                [c,s]=lasso(X,y,'Lambda',info.Lambda(li),args{:});
                single_b(:,li)=c;single_ic(li)=s.Intercept;single_mse(li)=s.MSE;
            end
            rows{j}=struct('id',sprintf('%s_s%d',q.id,standard),'b',{bits(b)},'ic',{bits(info.Intercept)}, ...
                'mse',{bits(info.MSE)},'lambda',{bits(info.Lambda)},'df',{bits(info.DF)},'shape',size(b), ...
                'single_b',{bits(single_b)},'single_ic',{bits(single_ic)},'single_mse',{bits(single_mse)}, ...
                'warning_id',wid,'warning_message',msg);
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
