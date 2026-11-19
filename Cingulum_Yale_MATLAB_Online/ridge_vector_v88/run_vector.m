function run_vector
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','misc');addpath(base);
for name={'ridgeCPM_vector','kfold_family','find_lambda','computeLambdaMax'}
    assert(strcmp(which(name{1}),fullfile(base,[name{1} '.m'])));
end
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);y=hex2num(char(q.outcomes));n=numel(y);A=[];V=[];
        if ~isempty(q.matrix),A=reshape(hex2num(char(q.matrix)),q.shape(:)');end
        if ~isempty(q.vectors),V=reshape(hex2num(char(q.vectors)),q.vector_shape(:)');end
        families=[(1:n)' q.family_ids(:)];lastwarn('','');
        try
            [qs,r,rank,pred,b,ic,lam]=ridgeCPM_vector(A,V,y,q.threshold,families,q.alpha,q.lambda_value,q.k,q.seed);
        catch e
            rows{j}=struct('id',q.id,'returned',false,'error_id',e.identifier,'error_message',e.message);
            continue;
        end
        [msg,wid]=lastwarn;
        labels=kfold_family(families,q.k,q.seed);
        F=zeros(0,n);
        if ~isempty(A)
            nr=size(A,1);loc=1:nr^2;
            if issymmetric(A(:,:,1,1)),loc=find(tril(true(nr),-1));end
            for t=1:size(A,4)
                page=reshape(A(:,:,:,t),nr^2,n);F=[F;page(loc,:)];
            end
        end
        if ~isempty(V),F=[F;V(:,1:n)];end
        igrid={};ilabel={};imse={};
        for fold=1:q.k
            if numel(q.lambda_value)==1,continue;end
            tr=labels~=fold;B=F(:,tr);yy=y(tr);grid=q.lambda_value;ki=2;
            if isempty(grid)
                [~,pv]=corr(B',yy);
                high=computeLambdaMax(B(pv<q.threshold,:)',yy,[],.01,true);
                grid=exp(linspace(log(high),log(high*.001),16));ki=5;
            end
            saved=rng;inner=crossvalind('Kfold',numel(yy),ki);rng(saved);
            [chosen,loss]=find_lambda(B,yy,grid,q.threshold,ki);
            assert(isequal(num2hex(chosen),num2hex(lam(fold))));
            igrid=[igrid;bits(sort(grid(:),'descend'))];ilabel=[ilabel;bits(inner)];imse=[imse;bits(loss)];
        end
        fields={qs,r,rank,pred,b,ic,lam};shapes=cellfun(@size,fields,'UniformOutput',false);
        rows{j}=struct('id',q.id,'returned',true,'q_s',num2hex(qs),'r_pearson',num2hex(r), ...
            'r_rank',num2hex(rank),'y',{bits(pred)},'coef_total',{bits(b)},'coef0_total',{bits(ic)}, ...
            'lambda_total',{bits(lam)},'labels',{bits(labels)},'inner_grid',{igrid},'inner_labels',{ilabel}, ...
            'inner_mse',{imse},'shapes',{shapes},'warning_id',wid,'warning_message',msg);
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(x)
if isempty(x),b=cell(0,1);else,b=cellstr(num2hex(double(x(:))));end
end
