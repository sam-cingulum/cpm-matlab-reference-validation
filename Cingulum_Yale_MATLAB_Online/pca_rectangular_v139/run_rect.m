function run_rect
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j); X=reshape(hex2num(char(q.x)),q.n,q.width); mu=mean(X,1); C=X-mu;
        [~,R]=qr(C,0); [~,~,V]=svd(C,'econ'); [~,~,W]=svd(R,'econ');
        lastwarn('',''); loading=pca(X,'NumComponents',1);[msg,wid]=lastwarn;
        v=orient(V(:,1)); w=orient(W(:,1));
        rows{j}=struct('id',q.id,'mean',{bits(mu)},'centered',{bits(C)},'upper',{bits(R(triu(true(q.width))))},...
            'loading',{bits(loading)},'direct_svd',{bits(v)},'reduced_svd',{bits(w)},'projected',{bits(X*loading)},...
            'direct_equals_pca',isequal(num2hex(v),num2hex(loading)),'reduced_equals_pca',isequal(num2hex(w),num2hex(loading)),...
            'warning_id',wid,'warning_message',msg);
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');out.release=version;
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function v=orient(v)
[~,j]=max(abs(v));v=v*sign(v(j));
end
function b=bits(x)
b=cellstr(num2hex(double(x(:))));
end
