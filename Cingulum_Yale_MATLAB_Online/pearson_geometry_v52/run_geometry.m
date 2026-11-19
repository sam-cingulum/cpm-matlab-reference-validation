function run_geometry
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
        U=A-mx; w=v-my;
        [r,p]=corr(A,v);
        f=struct(); f.r=hex(r);f.p=hex(p);
        f.reverse=hex(corr(v,A)); f.centered=hex(corr(U,w));
        f.single=zeros(size(r));nx=zeros(size(r));d=zeros(size(r));
        for l=1:size(A,2)
            f.single(l)=corr(A(:,l),v);nx(l)=norm(U(:,l));d(l)=dot(U(:,l),w);
        end
        f.single=hex(f.single); ny=norm(w);xy=U'*w;
        f.nx=hex(nx);f.ny=hex(ny);f.single_dot=hex(d);f.matrix_dot=hex(xy);
        f.gram_norm_x=hex(sqrt(diag(U'*U)));f.gram_norm_y=hex(sqrt(w'*w));
        f.vecnorm_x=hex(vecnorm(U));f.vecnorm_y=hex(vecnorm(w));
        f.matrix_unit=hex((U./nx')'*(w./ny));
        f.scale_x_first=hex(((U./nx')'*w)./ny);
        f.scale_y_first=hex((U'*(w./ny))./nx);
        % A dyadic shift changes the magnitudes without changing the exact covariance.
        f.shifted=hex(corr(A+128,v-256));
        % Centered coordinate contrasts and a complete indicator basis
        % distinguish normalization and covariance reduction on the same rows.
        H=eye(m);
        f.basis=hex(corr(A,H)); f.basis_y=hex(corr(v,H));
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
