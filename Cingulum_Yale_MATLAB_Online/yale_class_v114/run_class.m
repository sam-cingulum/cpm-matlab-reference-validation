function run_class
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','oop');addpath(base);
assert(strcmp(which('cpm'),fullfile(base,'cpm.m')) && strcmp(which('rcpm'),fullfile(base,'rcpm.m')));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows={};
    for j=1:numel(raw)
        q=raw(j);h=q.group;n=h.shape(3);A=reshape(hex2num(char(h.matrix)),h.shape(:)');
        clear subs;subs(1,n)=subject;
        for i=1:n
            subs(i)=subject(A(:,:,i,:),i,"synthetic","none");
        end
        g=group(subs);Y=hex2num(char(h.outcomes));p=phenotype("synthetic",Y);
        % Input stores contiguous control columns in MATLAB order.
        rawcontrols=reshape(hex2num(char(q.controls)),n,2);
        assert(isequal(size(rawcontrols),[n 2]));
        X=reshape(permute(g.all_edges,[1 3 2]),[],n);
        for mode=["cpm","rcpm"]
            if mode=="cpm", count=q.cpm_controls;else,count=q.rcpm_controls;end
            C=rawcontrols(:,1:count);if count==0,C=[];end
            opts=struct('control',C,'phenotype',p,'k',q.k,'seed',q.seed,'thresh',q.threshold,'lambda',1024);
            if q.alpha~=1e-6,opts.v_alpha=q.alpha;opts.v_valpha=q.alpha;end
            row=struct('id',char(string(q.id)+"_"+mode));
            try
                if mode=="cpm",obj=cpm(g,opts);else,obj=rcpm(g,opts);end
                lastwarn('','');obj.run();outtext=evalc('obj.evaluate();');[msg,wid]=lastwarn;next=rand;
                row.y=bits(obj.Y);row.coef_total=bits(obj.coef_total);row.coef0_total=bits(obj.coef0_total);
                row.lambda_total=bits(obj.lambda_total);row.next_uniform=num2hex(next);
                row.public_metrics=bits([obj.q_s;obj.r_pearson;obj.r_rank;obj.mse]);
                mse=sum((obj.Y-Y).^2)/n;qs=1-mse/var(Y,1);
                r=corr(obj.Y,Y);rank=corr(obj.Y,Y,'type','spearman');
                row.metrics=bits([qs;r;rank;mse]);row.transcript=outtext;
                rng(q.seed);part=cvpartition(n,'k',q.k);labels=zeros(n,1);masks=[];
                for fold=1:q.k
                    testidx=test(part,fold);tr=~testidx;labels(testidx)=fold;
                    if isempty(C),Z=[];elseif mode=="rcpm",Z=C(tr);else,Z=C(tr,:);end
                    if isempty(Z),[rho,prob]=corr(X(:,tr)',Y(tr));else,[rho,prob]=partialcorr(X(:,tr)',Y(tr),Z);end
                    masks=[masks;sign(rho).*(prob<q.threshold)];
                end
                row.labels=bits(labels);row.signed_masks=bits(masks);
                row.shapes={size(obj.Y),size(obj.coef_total),size(obj.coef0_total),size(obj.lambda_total),size(obj.q_s),size(obj.r_pearson),size(obj.r_rank),size(obj.mse)};
                row.warning_id=wid;row.warning_message=msg;row.returned=true;
            catch e
                row=struct('id',row.id,'returned',false,'error_id',e.identifier,'error_message',e.message);
            end
            rows{end+1}=row;
        end
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(x)
b=cellstr(num2hex(double(x(:))));
if isempty(x),b={};end
end
