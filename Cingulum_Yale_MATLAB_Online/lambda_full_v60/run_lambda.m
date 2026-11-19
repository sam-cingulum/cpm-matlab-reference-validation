function run_lambda
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
addpath(fullfile(pwd,'upstream','matlab','misc'));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    for i=1:numel(raw)
        c=raw(i);X=reshape(hex2num(char(c.x_hex)),c.n,c.m);Y=hex2num(char(c.y_hex));Y=Y(:);
        if isempty(c.weight_hex),w=[];else,w=hex2num(char(c.weight_hex))';end
        alpha=hex2num(c.alpha_hex);lastwarn('');
        [lambda,mse]=computeLambdaMax(X,Y,w,alpha,c.standardize);
        [msg,wid]=lastwarn;
        rows(i)=struct('id',c.id,'lambda',num2hex(lambda),'mse',num2hex(mse),'warning_id',wid,'warning_message',msg);
    end
    out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
