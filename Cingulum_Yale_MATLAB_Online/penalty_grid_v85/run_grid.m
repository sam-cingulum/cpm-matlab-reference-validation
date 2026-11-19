function run_grid
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
for rep=1:2
  rows=cell(1,numel(raw));
  for j=1:numel(raw)
    q=raw(j);x=hex2num(q.high);low=x*.001;hi=log(x);lo=log(low);
    points=linspace(hi,lo,q.n);grid=exp(points);scalar=zeros(1,q.n);
    for i=1:q.n,scalar(i)=exp(points(i));end
    step=(lo-hi)/(q.n-1);
    rows{j}=struct('id',q.id,'low',num2hex(low),'hi',num2hex(hi),'lo',num2hex(lo), ...
        'step',num2hex(step),'points',{bits(points)},'grid',{bits(grid)},'scalar',{bits(scalar)});
  end
  out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(v)
b=cellstr(num2hex(v(:)));
end
