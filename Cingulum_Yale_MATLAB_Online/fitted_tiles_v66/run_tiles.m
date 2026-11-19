function run_tiles
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
s=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(s.rows)*numel(s.widths)*numel(s.inner));count=0;
    for n=s.rows(:)'
        for w=s.widths(:)'
            for k=s.inner(:)'
                A=zeros(n,k);B=zeros(k,w);
                A(:,k-1)=-1; B(k-1,:)=1;
                A(:,k)=1+2^-27; B(k,:)=1-2^-27;
                C=A*B;
                assert(all(C(:)==0 | C(:)==-2^-54));
                count=count+1;
                rows{count}=struct('shape',[n w k],'fused',char('0'+(C(:)'~=0)));
            end
        end
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.release=version;out.run=getenv('GITHUB_RUN_ID');out.commit=getenv('GITHUB_SHA');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
