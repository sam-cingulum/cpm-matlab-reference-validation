function run_missing
assert(contains(version,'(R2026b) Update 1') && strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
assert(maxNumCompThreads==1);
q=jsondecode(fileread('input.json'));
for rep=1:2
    rows=cell(numel(q.cases),1);
    for i=1:numel(q.cases)
        c=q.cases(i);
        x=numeric_column(c.x_hex); y=numeric_column(c.y_hex);
        lastwarn('');
        try
            [b,s]=robustfit(x,y);
            [msg,wid]=lastwarn;
            names=fieldnames(s);
            v=struct();
            for k=1:numel(names)
                v.(names{k})=pack(s.(names{k}));
            end
            rows{i}=struct('id',c.id,'status','returned','warning_id',wid,'warning_message',msg,...
                'field_order',{names},'b',pack(b),'stats',v);
        catch err
            [msg,wid]=lastwarn;
            rows{i}=struct('id',c.id,'status','error','warning_id',wid,'warning_message',msg,...
                'error_id',err.identifier,'error_message',err.message);
        end
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.release=version; out.run=getenv('GITHUB_RUN_ID'); out.commit=getenv('GITHUB_SHA');
fid=fopen('original.json','w'); assert(fid>=0); fprintf(fid,'%s\n',jsonencode(out)); assert(fclose(fid)==0);
end

function x=numeric_column(v)
if isempty(v), x=zeros(0,1); else, x=hex2num(char(v)); x=x(:); end
end

function r=pack(v)
assert(isa(v,'double') && isreal(v)); r.shape=size(v); r.hex=cellstr(num2hex(v(:)));
end
