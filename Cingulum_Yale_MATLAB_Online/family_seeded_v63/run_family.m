function run_family
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
addpath(fullfile(pwd,'upstream','matlab','misc'));
raw=jsondecode(fileread('input.json'));
for rep=1:2
    for i=1:numel(raw)
        c=raw(i); fam=c.family(:);n=numel(fam); f=[(1:n)',fam];
        message='';identifier='';labels=[];lastwarn('');
        try
            switch c.arity
                case 1, labels=kfold_family(f);
                case 2, labels=kfold_family(f,c.k);
                case 3, labels=kfold_family(f,c.k,c.seed);
            end
        catch ME
            message=ME.message; identifier=ME.identifier;
        end
        [wm,wi]=lastwarn;
        corrected=[];
        if isempty(message) && c.k>=2
            rng(c.seed,'twister');perm=randperm(n);
            [families,~,group]=unique(fam);sizes=accumarray(group,1);
            pos=zeros(n,1);pos(perm)=1:n;
            first=accumarray(group,pos,[],@min);
            [~,order]=sortrows([-sizes,first],[1,2]);
            loads=zeros(1,c.k); corrected=zeros(n,1);
            for j=order(:)'
                [~,fold]=min(loads);
                corrected(fam==families(j))=fold;
                loads(fold)=loads(fold)+sizes(j);
            end
            assert(all(loads>0) && all(corrected>0));
        end
        rows(i)=struct('id',c.id,'labels',labels(:)','corrected',corrected(:)', ...
            'shape',size(labels),'error_id',identifier,'error_message',message,'warning_id',wi,'warning_message',wm);
    end
    out.repetitions(rep).rows=rows;
end
assert(isequaln(out.repetitions(1),out.repetitions(2)));
out.release=version;out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
