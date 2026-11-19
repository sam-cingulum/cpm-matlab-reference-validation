function run_solve
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('../ohbm_full_v57/input.json'));
for rep=1:2
    rows=cell(1,2); idx=0;
    for i=1:numel(raw)
        c=raw(i);if c.option~=4,continue;end
        idx=idx+1; q=c.request;M=permute(q.subject_matrices,[2 3 1]);y=q.outcomes(:);Z=q.covariates;
        n=numel(y);folds=cell(1,n);
        for held=1:n
            ix=setdiff(1:n,held);
            B=[reshape(M(:,:,ix),[],n-1)',y(ix)];W=[ones(n-1,1),Z(ix,:)];
            [Q,R,P]=qr(W,0); if ~isvector(P),[~,P]=max(P);end
            k=size(W,2);m=size(B,2);
            b=W\B; fitted=W*b;
            T=B(1:k,:);trisol=R\T;
            % Reveal how the public backslash behaves for a single reflector and a matrix RHS.
            first=W(:,P(1));[q1,r1]=qr(first,0);
            one=first\B; joint_q=Q'*B;
            projected=cell(1,k);
            for j=1:k
                projected{j}=bits(W(:,P(1:j))\B);
            end
            lifted=[R;zeros(n-1-k,k)]; liftedsol=lifted\[T;zeros(n-1-k,m)];
            f=struct('permutation',P(:)','Q',{bits(Q)},'R',{bits(R)},'beta',{bits(b)}, ...
                'fitted',{bits(fitted)},'residual',{bits(B-fitted)},'triangular',{bits(trisol)}, ...
                'lifted',{bits(liftedsol)},'single',{bits(one)},'q1',{bits(q1)},'r1',num2hex(r1), ...
                'joint_q',{bits(joint_q)},'prefix',{projected});
            folds{held}=f;
        end
        rows{idx}=struct('id',c.id,'folds',{folds});
    end
    out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function x=bits(v)
x=cellstr(num2hex(v(:)));
end
