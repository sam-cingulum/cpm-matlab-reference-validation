function run_qr_norm
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);n=q.n;x=zeros(n,1);ids=q.positions+1;x(ids)=7/8;x(ids(q.large+1))=1.5*2^26;
        b=mod((1:n)'*17,37)-18;
        [~,r]=qr([x,b],0);[~,s]=qr(x,0);
        rows{j}=struct('id',q.id,'r11',num2hex(r(1,1)),'r12',num2hex(r(1,2)),'r22',num2hex(r(2,2)), ...
            'single',num2hex(s(1,1)),'norm_tail',num2hex(norm(x(2:end))),'sum_squares',num2hex(sum(x.^2)));
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
