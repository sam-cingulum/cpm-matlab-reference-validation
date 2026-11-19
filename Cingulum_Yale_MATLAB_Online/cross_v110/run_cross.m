function run_cross
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','oop');addpath(base);
assert(strcmp(which('cross'),fullfile(base,'cross.m')));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    rows={};
    for j=1:numel(raw)
        q=raw(j);[g1,p1]=make_group(q.train);[g2,p2]=make_group(q.test);
        for mode=["cpm","rcpm"]
            opts=struct('control',[],'phenotype',p1,'phenotype1',p1,'phenotype2',p2, ...
                'model',mode,'taskID1',q.train.task,'taskID2',q.test.task,'k',q.k,'thresh',q.threshold, ...
                'seed',q.seed,'lambda',1024);
            if q.alpha~=1e-6
                opts.v_alpha=q.alpha;opts.v_valpha=q.alpha;
            end
            row=struct('id',char(string(q.id)+"_"+mode));
            try
                obj=cross(g1,g2,opts);rng(q.seed,'twister');lastwarn('','');
                obj.run();obj.evaluate();[msg,wid]=lastwarn;
                row.next_uniform=num2hex(rand);
                row.y=bits(obj.Y);row.r_pearson=num2hex(obj.r_pearson);row.r_rank=num2hex(obj.r_rank);
                row.mse=num2hex(obj.mse);row.q_s=num2hex(obj.q_s);
                X=obj.group1.all_edges;Z=obj.group2.all_edges;
                [r,p]=corr(X',p1.all_behav);
                row.positive=bits(p<q.threshold & r>0);row.negative=bits(p<q.threshold & r<0);
                row.train_edges=bits(X);row.test_edges=bits(Z);
                row.coef_total=bits(obj.coef_total);row.coef0_total=bits(obj.coef0_total);
                row.lambda_total=bits(obj.lambda_total);
                row.shapes={size(obj.Y),size(X),size(Z),size(obj.coef_total),size(obj.coef0_total),size(obj.lambda_total)};
                row.returned=true;row.warning_id=wid;row.warning_message=msg;
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

function [g,p]=make_group(q)
A=reshape(hex2num(char(q.matrix)),q.shape(:)');
n=q.shape(3);subjects(1,n)=subject;
for s=1:n
    subjects(s)=subject(A(:,:,s,:),s,"synthetic","none");
end
g=group(subjects);p=phenotype("synthetic",hex2num(char(q.outcomes)));
end

function b=bits(x)
b=cellstr(num2hex(double(x(:))));
end
