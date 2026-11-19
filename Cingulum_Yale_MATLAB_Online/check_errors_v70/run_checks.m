function run_checks
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
addpath(fullfile(pwd,'upstream','matlab','func'));
assert(strcmp(which('cpm_check_errors'),fullfile(pwd,'upstream','matlab','func','cpm_check_errors.m')));
raw=jsondecode(fileread('input.json'));
warning('off','backtrace');warning('off','verbose');
for rep=1:2
    rows=cell(1,numel(raw));
    for j=1:numel(raw)
        c=raw(j);q=c.request;x=unpack(q.x);y=unpack(q.y);folds=q.folds;
        err='';id='';lastwarn('','');outx=[];outy=[];
        transcript=evalc('try;[outx,outy]=cpm_check_errors(x,y,folds);catch ME;err=ME.message;id=ME.identifier;end');
        [last,warning_id]=lastwarn;
        notes=regexp(transcript,['\[' char(8) 'Warning: ([\s\S]*?)\]' char(8)],'tokens');
        messages=cell(1,numel(notes));
        for z=1:numel(notes)
            messages{z}=strtrim(regexprep(notes{z}{1},'\s+',' '));
        end
        assert(numel(messages)==count(transcript,'Warning: '));
        if ~isempty(messages),assert(strcmp(messages{end},last));end
        xres=[];yres=[];
        if isempty(err),xres=pack(outx);yres=pack(outy);end
        rows{j}=struct('id',c.id,'x',xres,'y',yres,'error',err,'error_id',id, ...
            'warnings',{messages},'last_warning',last,'warning_id',warning_id,'transcript',transcript);
    end
    out.repetitions(rep).rows=rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.run=getenv('GITHUB_RUN_ID');out.commit=getenv('GITHUB_SHA');out.release=version;
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function x=unpack(v)
if isempty(v.hex),x=zeros(v.shape(:)');else,x=reshape(hex2num(char(v.hex)),v.shape(:)');end
end
function s=pack(x)
if isempty(x),b=cell(0,1);else,b=cellstr(num2hex(x(:)));end
s=struct('shape',size(x),'hex',{b});
end
