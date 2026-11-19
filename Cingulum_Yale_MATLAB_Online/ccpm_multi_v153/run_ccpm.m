function run_ccpm
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','misc');addpath(base);
assert(strcmp(which('cCPM'),fullfile(base,'cCPM.m')));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);A=reshape(hex2num(char(q.matrix)),q.shape(:)');Y=hex2num(char(q.outcomes));
        rng(q.seed,'twister');labels=crossvalind('Kfold',size(Y,1),q.k);lastwarn('','');
        try
            [qs,r,rankcorr,y,w,mask]=cCPM(A,Y,q.threshold,q.k,q.seed);
        catch e
            rows{j}=struct('id',q.id,'returned',false,'error_id',e.identifier,'error_message',e.message);continue;
        end
        [msg,wid]=lastwarn;
        sizes=cellfun(@size,{qs,r,rankcorr,y,w,mask},'UniformOutput',false);
        nodes=q.shape(1);N=size(A,3);M=nodes*(nodes-1)/2;T=q.shape(4);X=zeros(M,N,T);
        for t=1:T
            for s=1:N
                X(:,s,t)=squareform(tril(A(:,:,s,t),-1));
            end
        end
        public_y=zeros(N,1);poly=[];sums=[];pp=[];
        for k=1:q.k
            train=labels~=k;test=~train;Z=X(:,train,:);means=squeeze(mean(Z,2));edgep=zeros(M,1);
            for e=1:M
                edge=squeeze(Z(e,:,:));
                if rank(edge)==T
                    [~,~,~,~,~,st]=canoncorr(edge,Y(train));edgep(e)=st.pF;
                end
            end
            use=edgep<q.threshold;coef=squeeze(w(k,:,:));features=zeros(N,1);
            for s=1:N
                features(s)=sum(sum(sum((squeeze(X(:,s,:))-means).*coef,2).*use))/2;
            end
            p=polyfit(features(train),Y(train),1);
            public_y(test)=p(1).*features(test)+p(2);poly=[poly;p(:)];sums=[sums;features];pp=[pp;edgep];
        end
        assert(isequal(public_y,y));
        rows{j}=struct('id',q.id,'returned',true,'q_s',num2hex(qs),'r_pearson',num2hex(r),'r_rank',num2hex(rankcorr), ...
            'y',{bits(y)},'weight',{bits(w)},'mask',{bits(mask)},'labels',{bits(labels)},'shapes',{sizes}, ...
            'scores',{bits(sums)},'fit',{bits(poly)},'p',{bits(pp)},'warning_id',wid,'warning_message',msg);
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
