function run_inner
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
cases=jsondecode(fileread('input.json'));
for rep=1:2
    for i=1:numel(cases)
        c=cases(i);n=c.n;e=ones(n,1);
        % Leaves are 1..n. Each subsequent index denotes the parent of two
        % previous nodes. The contrast always uses the same full n-vector.
        left=zeros(2*n,1);right=zeros(2*n,1);leaf=(1:2*n)';root=1;next=n;
        for new=2:n
            [root,next,left,right,leaf]=insert(root,new,next,left,right,leaf,n,e);
        end
        assert(next==2*n-1);
        for j=1:size(c.triples,1)
            abc=c.triples(j,:)+1;
            codes(j)=contrast(abc(1),abc(2),abc(3),n,e);
        end
        dense=cell(1,numel(c.dense));
        for j=1:numel(c.dense)
            x=c.dense(j).x(:); y=c.dense(j).y(:);
            u=x-mean(x);v=y-mean(y);
            dense{j}=bits([x'*y,y'*x,dot(x,y),mean(x),mean(y),norm(u),norm(v),u'*v,corr(x,y)]);
        end
        rows(i)=struct('n',n,'root',root,'left',left(n+1:next)','right',right(n+1:next)', ...
            'codes',codes,'dense',{dense});
    end
    out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end

function [root,next,left,right,leaf]=insert(root,new,next,left,right,leaf,n,e)
if root>n
    a=left(root); b=right(root); winner=contrast(leaf(a),leaf(b),new,n,e);
    if winner==1
        [child,next,left,right,leaf]=insert(b,new,next,left,right,leaf,n,e);
        right(root)=child;
        return
    elseif winner==2
        [child,next,left,right,leaf]=insert(a,new,next,left,right,leaf,n,e);
        left(root)=child;
        return
    end
end
old=root;next=next+1;root=next;left(root)=old;right(root)=new;leaf(root)=leaf(old);
end

function out=contrast(a,b,c,n,e)
ids=[a b c];out=0;
for j=1:3
    x=zeros(n,1);x(ids(j))=1;x(ids(mod(j,3)+1))=2^55;x(ids(mod(j+1,3)+1))=-2^55;
    v=x'*e;
    assert(v==0 || v==1);
    if v==1,out=out+2^(j-1);end
end
assert(any(out==[1,2,4]));
end

function out=bits(x)
out=cellstr(num2hex(x(:)));
end
