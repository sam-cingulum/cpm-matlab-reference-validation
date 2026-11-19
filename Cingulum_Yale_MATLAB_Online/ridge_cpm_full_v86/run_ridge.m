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
        igrid={};ilabel={};imse={};isel={};icoef={};iintercept={};ipred={};imean={};ise={};osel={};
        for fold=1:q.k
            tr=labels~=fold;B=F(:,tr);yy=y(tr);
            [~,ep]=corr(B',yy);
            chosen_edges=find(ep<=q.threshold);osel=[osel;bits(chosen_edges-1)];
            if numel(q.lambda_value)==1,continue;end
            grid=q.lambda_value;
            if isempty(grid)
                high=computeLambdaMax(B(ep<=q.threshold,:)',yy,[],.01,true);
                grid=exp(linspace(log(high),log(high*.001),16));
            end
            saved=rng;
            inner=crossvalind('Kfold',numel(yy),2);
            rng(saved);
            [chosen,loss]=find_lambda(B,yy,grid,q.threshold);
            assert(isequal(num2hex(chosen),num2hex(lam(fold))));
            after_inner=rng;
            ordered=sort(grid(:),'descend');
            imean=[imean;bits(mean(loss,1))];ise=[ise;bits(std(loss,0,1)/sqrt(2))];
            for li=1:numel(ordered)
                for z=1:2
                    itrain=inner~=z;itest=inner==z;E=B(:,itrain);target=yy(itrain);
                    [~,pv]=corr(E',target);selected=find(pv<=q.threshold);
                    args={'Alpha',1e-9,'Lambda',ordered(li)};
                    if size(E,1)>=300,args=[args,{'RelTol',1e-3,'MaxIter',100}];end
                    [coeff,info]=lasso(E(selected,:)',target,args{:});
                    forecast=B(selected,itest)'*coeff+info.Intercept;
                    assert(isequal(num2hex(mean((forecast-yy(itest)).^2)),num2hex(loss(z,li))));
                    isel=[isel;bits(selected-1)];icoef=[icoef;bits(coeff)];
                    iintercept=[iintercept;bits(info.Intercept)];ipred=[ipred;bits(forecast)];
                end
            end
            rng(after_inner);
            igrid=[igrid;bits(sort(grid(:),'descend'))];ilabel=[ilabel;bits(inner)];imse=[imse;bits(loss)];
        end
        fields={qs,qf,r,rank,pred,b,ic,lam};
        shapes=cellfun(@size,fields,'UniformOutput',false);
        rows{j}=struct('id',q.id,'q_s',num2hex(qs),'q_s_fold',{bits(qf)},'r_pearson',num2hex(r), ...
          'r_rank',num2hex(rank),'y',{bits(pred)},'beta_total',{bits(b)},'intercept_total',{bits(ic)}, ...
          'outer_selector',{osel},'inner_selector',{isel},'inner_coef',{icoef},'inner_intercept',{iintercept}, ...
          'inner_predictions',{ipred},'inner_means',{imean},'inner_se',{ise},'inner_grid',{igrid},'inner_labels',{ilabel},'inner_mse',{imse},'lambda_total',{bits(lam)},'labels',{bits(labels)},'shapes',{shapes},'warning_id',wid,'warning_message',msg);
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
