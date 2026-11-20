function run_long
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
assert(maxNumCompThreads==1);
raw=jsondecode(fileread('input.json'));
assert(numel(raw.cases)==272);
for rep=1:2
 for i=1:numel(raw.cases)
    c=raw.cases(i);
    x=hex2num(char(c.x_hex)); y=hex2num(char(c.y_hex));
    lastwarn('');
    if c.default_tune
        [b,s]=robustfit(x(:),y(:),c.weight_function,[],'off');
    else
        [b,s]=robustfit(x(:),y(:),c.weight_function,c.tune,'off');
    end
    [msg,wid]=lastwarn;
    names=fieldnames(s);
    v=struct();
    for k=1:numel(names)
        v.(names{k})=pack(s.(names{k}));
    end
    rows(i)=struct('id',c.id,'b',pack(b),'field_order',{names},'stats',v,'warning_id',wid,'warning_message',msg);
 end
 out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.release=version; out.run=getenv('GITHUB_RUN_ID'); out.commit=getenv('GITHUB_SHA');
fid=fopen('original.json','w'); assert(fid>=0);
fprintf(fid,'%s\n',jsonencode(out)); assert(fclose(fid)==0);
end

function r=pack(v)
assert(isa(v,'double') && isreal(v));
r.shape=size(v); r.hex=cellstr(num2hex(v(:)));
end
