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
        % Independently reproduce the original sequence of outer and inner RNG calls.
        rng(q.seed,'twister');
        if isempty(q.fold_labels),assert(isequal(crossvalind('Kfold',numel(y),q.k),labels));end
        nr=size(A,1);nc=size(A,2);nt=size(A,4);n=numel(y);sym=issymmetric(A(:,:,1,1));
        loc=1:nr*nc;
        if sym,loc=find(tril(true(nr,nc),-1));end
        F=zeros(numel(loc)*nt,n);
        for t=1:nt
            task=reshape(A(:,:,:,t),nr*nc,n);
            F((t-1)*numel(loc)+(1:numel(loc)),:)=task(loc,:);
        end
        igrid={};ilabel={};imse={};
        for fold=1:q.k
            tr=labels~=fold;B=F(:,tr);yy=y(tr);
            grid=q.lambda_value;
            if isempty(grid)
                [~,ep]=corr(B',yy);
                high=computeLambdaMax(B(ep<=q.threshold,:)',yy,[],.01,true);
                grid=exp(linspace(log(high),log(high*.001),16));
            end
            saved=rng;
            inner=crossvalind('Kfold',numel(yy),2);
            rng(saved);
            [chosen,loss]=find_lambda(B,yy,grid,q.threshold);
            assert(isequal(num2hex(chosen),num2hex(lam(fold))));
            igrid=[igrid;bits(sort(grid(:),'descend'))];ilabel=[ilabel;bits(inner)];imse=[imse;bits(loss)];
        end
        fields={qs,qf,r,rank,pred,b,ic,lam};
        shapes=cellfun(@size,fields,'UniformOutput',false);
        rows{j}=struct('id',q.id,'q_s',num2hex(qs),'q_s_fold',{bits(qf)},'r_pearson',num2hex(r), ...
          'r_rank',num2hex(rank),'y',{bits(pred)},'beta_total',{bits(b)},'intercept_total',{bits(ic)}, ...
          'inner_grid',{igrid},'inner_labels',{ilabel},'inner_mse',{imse},'lambda_total',{bits(lam)},'labels',{bits(labels)},'shapes',{shapes},'warning_id',wid,'warning_message',msg);
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
