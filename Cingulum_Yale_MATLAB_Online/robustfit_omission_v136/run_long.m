function run_long
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
assert(maxNumCompThreads==1);
raw=jsondecode(fileread('input.json'));
assert(numel(raw.cases)==88);
for rep=1:2
 for i=1:numel(raw.cases)
    c=raw.cases(i);
    x=hex2num(char(c.x_hex)); y=hex2num(char(c.y_hex));
    lastwarn('');
    [b,s]=robustfit(x(:),y(:));
    [msg,wid]=lastwarn;
    % no_sub includes the held-out subject in Yale 708999b predict_behavior.m.
    no_sub=numel(y)+1;
    cur_t=s.t(2);
    edge_r=sign(cur_t)*sqrt(cur_t^2/(no_sub-1-2+cur_t^2));
    edge_p=2*(1-tcdf(abs(cur_t),no_sub-1-2));
    names=fieldnames(s);
    v=struct();
    for k=1:numel(names)
        v.(names{k})=pack(s.(names{k}));
    end
    rows(i)=struct('id',c.id,'b',pack(b),'field_order',{names},'stats',v,'edge_r',num2hex(edge_r),'edge_p',num2hex(edge_p),'warning_id',wid,'warning_message',msg);
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
