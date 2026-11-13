function run_weighted_mldivide_six_disclosed_only()
% ONLY previously disclosed V9 original MATLAB-derived weight vectors.
% Direct WX\Wy for six synthetic cases; no robustfit or QR extra calls.
% The same script executes both uninstrumented and under LD_AUDIT, and
% the GitHub workflow compares every byte of both numerical JSON outputs.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
p=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(p,'inputs_v9_6_revealed.json')));
assert(strcmp(d.schema,'MATLAB_R2026B_AMD_V9_DISCLOSED_WLS_MICRO_FORENSICS_6'));
assert(d.source_unseen==false && numel(d.records)==6);
out=struct('id',{},'n',{},'weighted_backslash_first_hex',{},'weighted_backslash_repeat_hex',{},...
 'repeat_binary64_identical',{},'original_amd_disclosed_beta_hex',{},'amd_disclosed_beta_identical',{});
for k=1:numel(d.records)
 c=d.records(k);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
 w=hex2num(char(c.w_hex));x=x(:);y=y(:);w=w(:);
 n=numel(x);assert(n==c.n && all(isfinite([x;y;w])) && all(w>=0 & w<=1));
 WX=[ones(n,1),x].*sqrt(w);Wy=y.*sqrt(w);
 b1=WX\Wy;b2=WX\Wy;
 r=struct();r.id=c.id;r.n=n;
 r.weighted_backslash_first_hex=cellstr(num2hex(b1(:)));
 r.weighted_backslash_repeat_hex=cellstr(num2hex(b2(:)));
 r.repeat_binary64_identical=isequal(num2hex(b1),num2hex(b2));
 r.original_amd_disclosed_beta_hex=c.original_source_beta_hex;
 r.amd_disclosed_beta_identical=isequal(r.weighted_backslash_first_hex,cellstr(c.original_source_beta_hex));
 out(end+1)=r; %#ok<AGROW>
end
report=struct('status','RETROSPECTIVE_SIX_DISCLOSED_WEIGHTED_BACKSLASH_ONLY',...
 'release',version('-release'),'source_unseen',false,'records',out);
dest=getenv('WEIGHTED_LSQ_PROBE_OUTPUT');assert(~isempty(dest));
fd=fopen(fullfile(p,dest),'w');assert(fd>0);cleanup=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(report));
end
