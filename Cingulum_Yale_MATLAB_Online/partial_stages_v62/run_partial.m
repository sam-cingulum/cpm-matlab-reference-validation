function run_partial
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
raw=jsondecode(fileread('../ohbm_full_v57/input.json'));
for rep=1:2
    rows=cell(1,2); ii=0;
    for i=1:numel(raw)
        c=raw(i); if c.option~=4,continue;end
        ii=ii+1;q=c.request;M=permute(q.subject_matrices,[2 3 1]);Y=q.outcomes(:);Z=q.covariates;
        n=numel(Y);folds=cell(1,n);
        for held=1:n
            tr=setdiff(1:n,held); A=reshape(M(:,:,tr),[],n-1)'; y=Y(tr); z=Z(tr,:);
            [r,p]=partialcorr(A,y,z);
            B=[A y]; B0=B-mean(B);z0=z-mean(z); W=[ones(n-1,1),z];
            [Q,R]=qr(z0,0); [Q1,R1]=qr(W,0);
            f=struct('r',{bits(r)},'p',{bits(p)},'q',{bits(Q)},'R',{bits(R)});
            f.centered_ls=stages(B0-z0*(z0\B0));
            f.intercept_ls=stages(B-W*(W\B));
            f.centered_qr=stages(B0-Q*(Q'*B0));
            f.intercept_qr=stages(B-Q1*(Q1'*B));
            f.centered_tri=stages(B0-z0*(R\(Q'*B0)));
            f.intercept_tri=stages(B-W*(R1\(Q1'*B)));
            % Single-RHS solve versus shared covariance/cross-product rounding.
            each=zeros(size(B)); for col=1:size(B,2),each(:,col)=B0(:,col)-z0*(z0\B0(:,col));end
            f.centered_separate=stages(each);
            each=zeros(size(B)); for col=1:size(B,2),each(:,col)=B(:,col)-W*(W\B(:,col));end
            f.intercept_separate=stages(each);
            C=corr([B z]); v=size(B,2); keep=1:v; ctl=v+1:size(C,2);
            H=C(keep,keep)-C(keep,ctl)*(C(ctl,ctl)\C(ctl,keep));
            f.schur=bits(H(1:v-1,v)./sqrt(diag(H(1:v-1,1:v-1))*H(v,v)));
            folds{held}=f;
        end
        rows{ii}=struct('id',c.id,'folds',{folds});
    end
    out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end

function s=stages(B)
A=B(:,1:end-1);y=B(:,end);xy=A'*y;xx=sum(A.^2,1)';yy=sum(y.^2);
nx=vecnorm(A)'; ny=norm(y);
s=struct('resid',{bits(B)},'pearson',{bits(corr(A,y))},'joint',{bits(xy./sqrt(xx*yy))}, ...
    'product',{bits(xy./(sqrt(xx)*sqrt(yy)))},'sequential',{bits((xy./sqrt(xx))/sqrt(yy))}, ...
    'scaled',{bits((xy./nx)/ny)},'normalized',{bits((A./sqrt(xx)')'*(y./sqrt(yy)))});
end

function out=bits(v)
out=cellstr(num2hex(v(:)));
end
