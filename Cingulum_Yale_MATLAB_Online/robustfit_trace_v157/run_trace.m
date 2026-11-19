function run_trace
% Disclosed V155 diagnostic. All callbacks are independently authored weight laws.
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
raw=jsondecode(fileread('input.json'));
global CAPTURE157 WEIGHT157;
for rep=1:2
    rows={};
    for i=1:32
        c=raw.cases(i);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
        X=[ones(numel(x),1),x];WEIGHT157=c.weight_function;
        if c.default_tune
            switch WEIGHT157
                case 'andrews', tune=1.339;
                case 'bisquare', tune=4.685;
                case 'cauchy', tune=2.385;
                case 'fair', tune=1.4;
                case 'huber', tune=1.345;
                case 'logistic', tune=1.205;
                case 'talwar', tune=2.795;
                case 'welsch', tune=2.985;
            end
            [b,s]=robustfit(x,y,WEIGHT157);
        else
            tune=c.tune;[b,s]=robustfit(x,y,WEIGHT157,tune);
        end
        CAPTURE157={};[cb,cs]=robustfit(x,y,@capture,tune);
        calls=CAPTURE157;
        for k=1:numel(calls)
            w=hex2num(char(calls{k}.w));wx=X.*sqrt(w);wy=y.*sqrt(w);
            [Q,R,p]=qr(wx,'econ','vector');
            calls{k}.wx=bits(wx);calls{k}.wy=bits(wy);calls{k}.q=bits(Q);
            calls{k}.r=bits(R);calls{k}.pivot=bits(p);
            calls{k}.beta=bits(wx\wy);
        end
        [Q,R,p]=qr(X,'econ','vector');a=zeros(2,1);a(p)=R\(Q'*y);
        fields=fieldnames(s);matches=struct;
        for k=1:numel(fields)
            key=fields{k};matches.(key)=isequal(num2hex(s.(key)(:)),num2hex(cs.(key)(:)));
        end
        final_w=s.w;wx=X.*sqrt(final_w);wy=y.*sqrt(final_w);
        rows{end+1}=struct('id',c.id,'b',{bits(b)},'callback_b',{bits(cb)},...
            'stats',packstats(s),'callback_stats',packstats(cs),'same_stats',matches,...
            'initial_q',{bits(Q)},'initial_r',{bits(R)},'initial_pivot',{bits(p)},...
            'initial_b',{bits(a)},'calls',{calls},'final_solve',{bits(wx\wy)},...
            'residual_matrix',{bits(y-X*b)},'residual_explicit',{bits(y-(b(1)+x*b(2)))});
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
out.source_unseen=false;
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function w=capture(u)
global CAPTURE157 WEIGHT157;
switch WEIGHT157
    case 'andrews'
        z=u;z(z==0)=eps;w=(abs(z)<pi).*sin(z)./z;
    case 'bisquare',w=(abs(u)<1).*(1-u.^2).^2;
    case 'cauchy',w=1./(1+u.^2);
    case 'fair',w=1./(1+abs(u));
    case 'huber',w=1./max(1,abs(u));
    case 'logistic'
        z=u;z(z==0)=eps;w=tanh(z)./z;
    case 'talwar',w=double(abs(u)<1);
    case 'welsch',w=exp(-u.^2);
end
CAPTURE157{end+1}=struct('u',{bits(u)},'w',{bits(w)});
end
function b=bits(x)
b=cellstr(num2hex(double(x(:))));
end
function r=packstats(s)
fields=fieldnames(s);r=struct;
for k=1:numel(fields)
    name=fields{k};r.(name)=struct('shape',size(s.(name)),'hex',{bits(s.(name))});
end
end
