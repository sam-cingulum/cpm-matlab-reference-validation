function run_pca_two
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);X=reshape(hex2num(char(q.x)),q.n,2);
        mu=mean(X,1);C=X-mu;[~,R]=qr(C,0);
        [~,~,V]=svd(C,'econ');[~,~,W]=svd(R,'econ');
        lastwarn('','');loading=pca(X,'NumComponents',1);[msg,wid]=lastwarn;
        rows{j}=struct('id',q.id,'mean',{bits(mu)},'centered',{bits(C)},'upper',{bits([R(1,1);R(1,2);R(2,2)])}, ...
          'direct_svd',{bits(orient(V(:,1)))},'reduced_svd',{bits(orient(W(:,1)))},'loading',{bits(loading)}, ...
          'projected',{bits(X*loading)},'shapes',size(loading),'warning_id',wid,'warning_message',msg);
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function out=orient(v)
[~,j]=max(abs(v));out=v*sign(v(j));
end
function b=bits(x)
b=cellstr(num2hex(x(:)));
end
