function run_startup_matrix()
% Diagnostic only; record entry before performing any qualification check.
root=fileparts(mfilename('fullpath'));
log=fullfile(root,'out','entry.txt');
mark(log,'MATLAB function entered');
mark(log,['version=',version]);
mark(log,sprintf('entry maxNumCompThreads=%d',maxNumCompThreads));
keys={'MKL_NUM_THREADS','OMP_NUM_THREADS','MKL_CBWR'};
fid=fopen('/proc/self/environ','rb'); assert(fid>=0);
raw=char(fread(fid,Inf,'*uint8').'); fclose(fid);
parts=strsplit(raw,char(0));
for j=1:numel(keys)
    prefix=[keys{j},'=']; found=parts(startsWith(parts,prefix));
    mark(log,sprintf('initial %s count=%d',keys{j},numel(found)));
    for k=1:numel(found)
        mark(log,['initial ',keys{j},'=',safe_value(found{k}(numel(prefix)+1:end))]);
    end
    mark(log,['current ',keys{j},'=',safe_value(getenv(keys{j}))]);
end
fid=fopen('/proc/self/cmdline','rb'); assert(fid>=0);
raw=char(fread(fid,Inf,'*uint8').'); fclose(fid);
args=strsplit(raw,char(0),'CollapseDelimiters',false);
if isempty(args{end}), args(end)=[]; end
mark(log,sprintf('argv argc=%d',numel(args)));
for j=1:numel(args)
    a=args{j};
    if j==1
        [~,name,ext]=fileparts(a); value=[name,ext];
    elseif any(strcmp(a,{'-singleCompThread','-batch','-r','-nodesktop','-nosplash','-nojvm','-nodisplay','-logfile'}))
        value=a;
    else
        value='<other argument redacted>';
    end
    mark(log,sprintf('argv[%d]=%s',j-1,value));
end
mark(log,sprintf('argv -singleCompThread count=%d',sum(strcmp(args,'-singleCompThread'))));
mark(log,sprintf('argv -batch count=%d',sum(strcmp(args,'-batch'))));
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version,'26.2.0.3433840 (R2026b) Update 1'));
mark(log,'STARTUP_MATRIX_ENTRY_PASS');
end

function value=safe_value(value)
% Only allow the three known numerical controls, never arbitrary process data.
if isempty(value), value='<empty>'; return; end
if isempty(regexp(value,'^(1|[0-9]{1,3}|COMPATIBLE|AUTO|AVX2|AVX512|SSE4_2|STRICT)$','once'))
    value='<unexpected value redacted>';
end
end

function mark(log,message)
fid=fopen(log,'a'); assert(fid>=0);
fprintf(fid,'%s\n',message); fclose(fid);
fprintf(1,'%s\n',message);
end
