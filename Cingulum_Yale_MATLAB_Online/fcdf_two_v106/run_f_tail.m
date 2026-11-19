function run_f_tail
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        q=raw(j);f=hex2num(q.f);d=q.df;a=1;b=d/2;
        z=2*f/(2*f+d);w=d/(2*f+d);
        rows{j}=struct('id',q.id,'upper',num2hex(fcdf(f,2,d,'upper')),'z',num2hex(z),'w',num2hex(w), ...
            'beta_z',num2hex(betainc(z,a,b,'upper')),'beta_w',num2hex(betainc(w,b,a)), ...
            'beta_complement',num2hex(betainc(1-z,b,a)),'reversed',num2hex(betainc(1-w,a,b,'upper')));
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
