function run_stages
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
cases=jsondecode(fileread('../yale_cpm_main_v50/input.json'));
for rep=1:2
 for i=1:numel(cases)
    c=cases(i); x=permute(c.request.three_d.subject_matrices,[2 3 1]); y=c.request.outcomes(:);
    n=numel(y);k=c.request.k; b=floor(n/k);rng(c.seed,'twister');order=randperm(n);
    if issymmetric(x(:,:,1))
        ix=find(triu(true(size(x,1)),1)); x=reshape(x,[],n);x=x(ix,:);
    else
        x=reshape(x,[],n);
    end
    folds=cell(1,k);
    for j=1:k
        held=order(1+b*(j-1):b*j);train=setdiff(order,held);
        A=x(:,train)';v=y(train);m=numel(v);mx=mean(A);my=mean(v);
        U=A-mx; w=v-my; sx=std(A);sy=std(v); z=U./sx; t=w./sy;
        xx=sum(U.^2);yy=sum(w.^2);xy=U'*w;
        [r,p]=corr(A,v);
        f=struct();f.r=hex(r);f.p=hex(p);
        f.mx=hex(mx);f.my=hex(my);f.sx=hex(sx);f.sy=hex(sy);
        f.xx=hex(xx);f.yy=hex(yy);f.xy=hex(xy);
        f.product_roots=hex(xy./(sqrt(xx)'*sqrt(yy)));
        f.root_product=hex(xy./sqrt(xx'*yy));
        f.sample_cov=hex((xy/(m-1))./(sx'*sy));
        f.zscore_dot=hex((z'*t)/(m-1));
        f.zscore_sum=hex(sum(z.*t,1)'/(m-1));
        f.norm_dot=hex((U./sqrt(xx))'*(w./sqrt(yy)));
        f.std_scaled_norms=hex(xy./((sx*sqrt(m-1))'*(sy*sqrt(m-1))));
        f.matrix_cov=hex(corrcoef([A,v]));f.matrix_corr=hex(corr([A,v]));
        f.covariance=hex(cov([A,v]));f.cov_xy=hex(cov([A,v],1));
        folds{j}=f;
    end
    rows(i)=struct('id',c.id,'folds',{folds});
 end
 out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.run=getenv('GITHUB_RUN_ID');out.commit=getenv('GITHUB_SHA');
fid=fopen('original.json','w'); assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function c=hex(v)
c=cellstr(num2hex(v(:)));
end
