function run_contrasts
assert(contains(version,'(R2026b) Update 1')&&strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
 for i=1:numel(raw)
    n=raw(i).n;w=raw(i).width;triples=nchoosek(1:n,3);one=ones(n,1);
    code=zeros(size(triples,1),w,'uint8');
    for j=1:size(triples,1)
        pos=triples(j,:);
        for small=1:3
            t=zeros(n,1);t(pos(small))=1;
            z=pos([1:small-1,small+1:3]);t(z(1))=2^55;t(z(2))=-2^55;
            a=repmat(t,1,w);
            result=a'*one;
            assert(all(result==0 | result==1));
            code(j,:)=code(j,:)+uint8(result')*uint8(2^(small-1));
        end
    end
    rows(i)=struct('n',n,'width',w,'triple_count',size(triples,1),'signatures',{cellstr(char(double(code')+48))});
 end
 out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.run=getenv('GITHUB_RUN_ID');out.commit=getenv('GITHUB_SHA');out.release=version;
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
