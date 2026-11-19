function run_qr_tree
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
cases=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(cases));
    for i=1:numel(cases)
        q=cases(i);n=q.n;stage=q.stage;offset=1+(stage==3);leaves=n-offset;
        X=reshape(q.x,n,2);[~,R]=qr(X,0);
        codes=zeros(1,size(q.triples,1));
        for k=1:numel(codes)
            codes(k)=contrast(q.triples(k,:)+1,n,stage);
        end
        left=zeros(2*leaves,1);right=left;leaf=(1:2*leaves)';root=1;next=leaves;
        valid=true;
        for new=2:leaves
            [root,next,left,right,leaf,valid]=insert(root,new,next,left,right,leaf,leaves,n,stage,offset);
            if ~valid,break;end
        end
        rows{i}=struct('id',q.id,'n',leaves,'stage',stage,'codes',codes,'r',{cellstr(num2hex([R(1,1);R(1,2);R(2,2)]))}, ...
            'valid_tree',valid,'root',root,'left',left(leaves+1:next)','right',right(leaves+1:next)');
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function [root,next,left,right,leaf,valid]=insert(root,new,next,left,right,leaf,m,n,stage,offset)
valid=true;
if root>m
    a=left(root);b=right(root);code=contrast([leaf(a),leaf(b),new]+offset,n,stage);
    if ~ismember(code,[1 2 4]),valid=false;return;end
    if code==1
        [child,next,left,right,leaf,valid]=insert(b,new,next,left,right,leaf,m,n,stage,offset);
        right(root)=child;return;
    elseif code==2
        [child,next,left,right,leaf,valid]=insert(a,new,next,left,right,leaf,m,n,stage,offset);
        left(root)=child;return;
    end
end
old=root;next=next+1;root=next;left(root)=old;right(root)=new;leaf(root)=leaf(old);
end
function code=contrast(ids,n,stage)
code=0;
for j=1:3
    X=zeros(n,2);
    if stage==2
        X(1,1)=-1;X(ids,1)=4;
        % R11=7, so each tail entry of the Householder vector is exactly -1/2.
        other=ids([1:j-1,j+1:3]);
        X(ids(j),2)=-2;X(other(1),2)=-2^56;X(other(2),2)=2^56;
        [~,r]=qr(X,0);
        hit=(r(1,2)~=0);
    else
        col=1+(stage==3);
        if stage==3,X(1,1)=1;end
        X(ids,col)=7/8;X(ids(j),col)=1.5*2^26;
        [~,r]=qr(X,0);
        hit=abs(r(col,col))>1.5*2^26;
    end
    code=code+double(hit)*2^(j-1);
end
end
