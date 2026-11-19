function run_main_probe
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
addpath(genpath(fullfile(pwd,'upstream','matlab')));
cases=jsondecode(fileread('input.json'));
for rep=1:2
 for i=1:numel(cases)
    c=cases(i); req=c.request;
    X=permute(req.three_d.subject_matrices,[2 3 1]); Y=req.outcomes(:);
    n=numel(Y); k=req.k; threshold=req.p_threshold;
    rng(c.seed,'twister'); lastwarn('');
    [prediction,perf]=cpm_main(X,Y,'pthresh',threshold,'kfolds',k);
    [msg,wid]=lastwarn;
    [flat,yy]=cpm_check_errors(X,Y,k);
    rng(c.seed,'twister');
    [pred2,perf2]=cpm_main(flat,Y,'pthresh',threshold,'kfolds',k);
    assert(isequaln(hex(prediction),hex(pred2)) && isequaln(hex(perf),hex(perf2)));
    rng(c.seed,'twister'); perm=randperm(n);
    rng(c.seed,'twister'); pred_cv=cpm_cv(flat,Y,threshold,k);
    assert(isequal(hex(pred_cv),hex(prediction)));
    reconstructed=zeros(n,1); folds=cell(1,k); b=floor(n/k);
    for j=1:k
        held=perm((j-1)*b+1:j*b); train=setdiff(perm,held);
        [r,p,mask,coef]=cpm_train(flat(:,train),yy(train),threshold);
        held_pred=cpm_test(flat(:,held),coef,mask);
        reconstructed(held)=held_pred;
        strengths=nanmean(flat(mask>0,:),1)-nanmean(flat(mask<0,:),1);
        f=struct();
        f.held=held(:)'-1;f.train=train(:)'-1;
        f.r=hex(r);f.p=hex(p);f.mask=mask(:)';
        f.train_summary=hex(strengths(train));f.held_summary=hex(strengths(held));
        f.coef=hex(coef);f.held_pred=hex(held_pred);
        folds{j}=f;
    end
    assert(isequal(hex(reconstructed),hex(prediction)));
    rows(i)=struct('id',c.id,'flat',{hex(flat)},'folds',{folds},'prediction',{hex(prediction)},'performance',{hex(perf)},'warning_id',wid,'warning_message',msg);
 end
 out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.run=getenv('GITHUB_RUN_ID');out.commit=getenv('GITHUB_SHA');
fid=fopen('original.json','w'); assert(fid>=0); fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end

function values=hex(v)
values=cellstr(num2hex(v(:)));
end
