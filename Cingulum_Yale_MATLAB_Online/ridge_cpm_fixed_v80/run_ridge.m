function run_ridge
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','misc');addpath(base);
assert(strcmp(which('ridgeCPM'),fullfile(base,'ridgeCPM.m')));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);A=reshape(hex2num(char(q.matrix)),q.shape(:)');y=hex2num(char(q.outcomes));
        if isempty(q.fold_labels)
            rng(q.seed,'twister');labels=crossvalind('Kfold',numel(y),q.k);k=q.k;
        else
            labels=q.fold_labels(:);k=labels;
        end
        lastwarn('');
        [qs,qf,r,rank,pred,b,ic,lam]=ridgeCPM(A,y,q.threshold,q.alpha,q.lambda_value,k,q.seed);
        [msg,wid]=lastwarn;
        fields={qs,qf,r,rank,pred,b,ic,lam};
        shapes=cellfun(@size,fields,'UniformOutput',false);
        rows{j}=struct('id',q.id,'q_s',num2hex(qs),'q_s_fold',{bits(qf)},'r_pearson',num2hex(r), ...
          'r_rank',num2hex(rank),'y',{bits(pred)},'beta_total',{bits(b)},'intercept_total',{bits(ic)}, ...
          'lambda_total',{bits(lam)},'labels',{bits(labels)},'shapes',{shapes},'warning_id',wid,'warning_message',msg);
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
