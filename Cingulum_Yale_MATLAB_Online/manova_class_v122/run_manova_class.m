function run_manova_class
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
base=fullfile(pwd,'upstream','matlab','oop');addpath(base);addpath(fullfile(base,'HotellingT2'));
assert(strcmp(which('manova'),fullfile(base,'manova.m')));
raw=jsondecode(fileread('input.json'));
% Resolve the relative HotellingT2 path inside the original class.
origin=pwd;cd(base);cleanup=onCleanup(@()cd(origin));
for rep=1:2
    rows={};
    for j=1:numel(raw)
        q=raw(j);s=q.shape(1);n=q.shape(3);A=reshape(hex2num(char(q.matrix)),q.shape(:)');
        clear subs;subs(1,n)=subject;
        for i=1:n,subs(i)=subject(A(:,:,i,:),i,"synthetic","none");end
        g=group(subs);diag=q.labels(:);p=phenotype("synthetic",diag);
        obj=manova(g,struct('phenotype',p,'diagnosis',diag));
        row=struct('id',q.id);
        [pid,pn]=obj.my_fdr(hex2num(char(q.prob)),.05);row.pid=num2hex(pid);row.pn=num2hex(pn);
        N=zeros(268);ij=reshape(q.coords,[],2);
        N(sub2ind(size(N),ij(:,1)+1,ij(:,2)+1))=1;
        [mask,area]=obj.my_largestCC(N(tril(true(268),-1)));
        row.cc_indices=bits(find(mask));row.area=num2hex(area);
        for op=["run_zero","run_one","perm","hotelling","nbs","empty_cc"]
            rng(q.seed,'twister');
            resp=struct('returned',true,'error_id','','error_message','');
            try
                switch op
                    case "run_zero",obj.run();
                    case "run_one",v=obj.run();
                    case "perm",[mat,th,lcc]=obj.permTest(zeros(g.num_edge,1),.05,1);
                    case "hotelling",v=obj.HottelingT();
                    case "nbs",v=obj.myNBSfdr(zeros(g.num_edge,1),.05,1);
                    case "empty_cc",[v,largest]=obj.my_largestCC(zeros(268*267/2,1));
                end
            catch e
                resp=struct('returned',false,'error_id',e.identifier,'error_message',e.message);
            end
            row.(op)=resp;
        end
        row.class_state=cellfun(@size,{obj.pval,obj.statistics,obj.dimensions,obj.lambda_total},'UniformOutput',false);
        rows{end+1}=row;
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen(fullfile(origin,'original.json'),'w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function b=bits(x)
b=cellstr(num2hex(double(x(:))));
end
