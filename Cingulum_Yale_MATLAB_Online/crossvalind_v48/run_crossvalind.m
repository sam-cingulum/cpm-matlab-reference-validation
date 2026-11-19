function run_crossvalind
assert(contains(version,'(R2026b) Update 1'));
cases=jsondecode(fileread('input.json'));
for rep=1:2
 for i=1:numel(cases)
    c=cases(i);
    rng(c.seed,'twister');
    for j=1:size(c.shapes,1)
        blocks(j).labels=double(crossvalind('Kfold',c.shapes(j,1),c.shapes(j,2)))';
        blocks(j).next_hex=num2hex(rand());
    end
    rows(i)=struct('seed',c.seed,'blocks',blocks);
 end
 out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.release=version; out.run=getenv('GITHUB_RUN_ID'); out.commit=getenv('GITHUB_SHA');
fid=fopen('original.json','w'); assert(fid>=0);
fprintf(fid,'%s\n',jsonencode(out)); assert(fclose(fid)==0);
end
