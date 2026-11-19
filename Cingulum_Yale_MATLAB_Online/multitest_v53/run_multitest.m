function run_multitest
assert(contains(version,'(R2026b) Update 1')); maxNumCompThreads(1);
addpath(fullfile(pwd,'upstream','matlab','oop'));
raw=jsondecode(fileread('input.json'));
for rep=1:2
 for i=1:numel(raw)
    c=raw(i); p=reshape(hex2num(char(c.p_hex)),c.shape(:)');alpha=hex2num(c.alpha_hex);
    row=struct();row.id=c.id;row.shape=size(p);
    methods={'pdep','dep'};
    for j=1:2
        [h,crit,ci,adj]=fdr_bh(p,alpha,methods{j},'no');
        assert(isequal(size(h),size(p)) && isequal(size(adj),size(p)));
        row.(methods{j})=struct('adjusted',{bits(adj)},'rejected',{bits(double(h))},'critical',num2hex(crit),'coverage',num2hex(ci));
    end
    [adj,h]=bonf_holm(p,alpha);
    assert(isequal(size(h),size(p)) && isequal(size(adj),size(p)));
    row.holm=struct('adjusted',{bits(adj)},'rejected',{bits(double(h))});
    % Independent closure of all Bonferroni intersection tests, expressed
    % using rank-tail subset size and a prefix maximum for each test.
    [ordered,ix]=sort(p(:));m=numel(p);corrected=zeros(m,1);
    for rank=1:m
        corrected(ix(rank))=min(1,max(ordered(1:rank).*(m:-1:(m-rank+1))'));
    end
    row.corrected=struct('adjusted',{bits(corrected)},'rejected',{bits(double(corrected<=alpha))});
    rows(i)=row;
 end
 out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.run=getenv('GITHUB_RUN_ID');out.commit=getenv('GITHUB_SHA');out.release=version;
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function c=bits(v)
c=cellstr(num2hex(v(:)));
end
