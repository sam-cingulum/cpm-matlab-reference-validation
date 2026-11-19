function run_pca_auto
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','misc');addpath(base);
assert(strcmp(which('ridgeCPM_PCA'),fullfile(base,'ridgeCPM_PCA.m')));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);A=reshape(hex2num(char(q.matrix)),q.shape(:)');Y=[hex2num(char(q.outcomes)) hex2num(char(q.second_outcome))];
        assert(q.k==10 && q.seed==665 && isempty(q.fold_labels));
        rng(665,'twister');labels=crossvalind('Kfold',size(Y,1),10);
        lastwarn('','');
        try
            [qs,qf,r,rank,y,behavior,loadings,b,ic,lam]=ridgeCPM_PCA(A,Y,q.threshold,q.alpha);
        catch e
            rows{j}=struct('id',q.id,'returned',false,'error_id',e.identifier,'error_message',e.message);
            continue;
        end
        [msg,wid]=lastwarn;
        fields={qs,qf,r,rank,y,behavior,loadings,b,ic,lam};shapes=cellfun(@size,fields,'UniformOutput',false);
        rows{j}=struct('id',q.id,'returned',true,'q_s',num2hex(qs),'q_s_fold',{bits(qf)},'r_pearson',num2hex(r), ...
            'r_rank',num2hex(rank),'y',{bits(y)},'new_behav',{bits(behavior)},'pca_coef_total',{bits(loadings)}, ...
            'coef_total',{bits(b)},'coef0_total',{bits(ic)},'lambda_total',{bits(lam)},'labels',{bits(labels)}, ...
            'shapes',{shapes},'warning_id',wid,'warning_message',msg);
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
