function run_ohbm
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
addpath(fullfile(pwd,'upstream'));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    for i=1:numel(raw)
        c=raw(i); q=c.request; option=c.option;
        M=permute(q.subject_matrices,[2 3 1]); Y=q.outcomes(:); Z=q.covariates;
        n=numel(Y); d=size(M,1); alpha=q.p_threshold;
        if isvector(Z), Z=Z(:); end
        state=warning; lastwarn('');
        [rp,rn,rc]=predict_behavior(M,Y,alpha,option,Z);
        [msg,id]=lastwarn; warning(state);
        predicted=zeros(n,3); folds=cell(1,n);
        for held=1:n
            train=setdiff(1:n,held);
            A=reshape(M(:,:,train),[],n-1)'; y=Y(train); f=struct();
            switch option
                case 1
                    [r,p]=corr(A,y);
                case 2
                    [r,p]=corr(A,y,'type','Spearman');
                case 3
                    r=zeros(d); p=zeros(d); edges=cell(1,d*(d-1)/2);
                    pos=0;
                    for col=1:d
                        for row=1:col-1
                            [b,s]=robustfit(A(:,row+(col-1)*d),y);
                            t=s.t(2); df=n-3;
                            r(row,col)=sign(t)*sqrt(t^2/(df+t^2));p(row,col)=2*(1-tcdf(abs(t),df));
                            pos=pos+1;
                            edges{pos}=bits([b(:);s.mad_s;s.ols_s;s.robust_s;s.s;s.se(2);t;p(row,col);r(row,col)]);
                        end
                    end
                    r=r+r'; p=p+p'; f.robust_edges=edges;
                case 4
                    [r,p]=partialcorr(A,y,Z(train,:));
            end
            r=reshape(r,d,d);p=reshape(p,d,d);pm=r>0 & p<alpha;nm=r<0 & p<alpha;
            strengths=zeros(n,2);
            for s=1:n
                strengths(s,:)=[sum(sum(M(:,:,s).*pm)),sum(sum(M(:,:,s).*nm))]/2;
            end
            X=strengths(train,:); one=ones(n-1,1);
            bp=regress(y,[X(:,1),one]);bn=regress(y,[X(:,2),one]);bc=regress(y,[X,one]);
            tp=strengths(held,1);tn=strengths(held,2);
            predicted(held,:)=[bp(1)*tp+bp(2),bn(1)*tn+bn(2),bc(1)*tp+bc(2)*tn+bc(3)];
            f.r=bits(r); f.p=bits(p); f.mask=reshape(double(pm)-double(nm),1,[]);
            f.pos=bits(strengths(:,1));f.neg=bits(strengths(:,2));
            f.coef=bits([bp;bn;bc]);f.pred=bits(predicted(held,:));folds{held}=f;
        end
        direct=[rp,rn,rc]; rebuilt=zeros(1,3);
        for k=1:3, rebuilt(k)=corr(predicted(:,k),Y); end
        assert(isequal(bits(direct),bits(rebuilt)),'original returns differ from fold reconstruction');
        rows(i)=struct('id',c.id,'folds',{folds},'prediction',{bits(predicted)},'performance',{bits(direct)},'warning_id',id,'warning_message',msg);
    end
    out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.run=getenv('GITHUB_RUN_ID');out.commit=getenv('GITHUB_SHA');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end

function result=bits(x)
result=cellstr(num2hex(x(:)));
end
