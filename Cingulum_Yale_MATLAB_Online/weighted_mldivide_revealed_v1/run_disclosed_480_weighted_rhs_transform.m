function run_disclosed_480_weighted_rhs_transform()
% Original MathWorks R2026b weighted mldivide; ALL synthetic V9 x/y/w source
% was already publicly exposed by action run 43342252905. NOT SOURCE-UNSEEN.
% Deliberately performs no independent QR calls: only original WX\Wy twice
% per case so DGEQP3/DORMQR/DTRSV trace can be paired unambiguously.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
root=fileparts(mfilename('fullpath'));
data=jsondecode(fileread(fullfile(root,'inputs_v9_480_disclosed.json')));
assert(strcmp(data.schema,'ORIGINAL_MATHWORKS_R2026B_V9_DISCLOSED_480_WEIGHTED_BACKSLASH_DORMQR_INPUT'));
assert(~data.source_unseen && data.case_count==480 && numel(data.records)==480);
records=struct('id',{},'n',{},'beta_hex',{},'beta_repeat_hex',{},'repeat_identical',{});
for k=1:480
 q=data.records(k);
 x=hex2num(char(q.x_hex));y=hex2num(char(q.y_hex));w=hex2num(char(q.w_hex));
 x=x(:);y=y(:);w=w(:);n=numel(x);
 assert(n==q.n && numel(y)==n && numel(w)==n && all(isfinite([x;y;w])) && all(w>=0&w<=1));
 WX=[ones(n,1),x].*sqrt(w);Wy=y.*sqrt(w);
 b=WX\Wy;b2=WX\Wy;
 assert(all(isfinite([b;b2])) && isequal(num2hex(b),num2hex(b2)));
 r=struct();r.id=q.id;r.n=n;r.beta_hex=cellstr(num2hex(b(:)));
 r.beta_repeat_hex=cellstr(num2hex(b2(:)));r.repeat_identical=true;
 records(end+1)=r; %#ok<AGROW>
 if mod(k,80)==0
  fprintf('DISCLOSED_V9_WLS_DORMQR 480 ORIGINAL_MATLAB cases=%d\n',k);
 end
end
out=struct('status','DISCLOSED_V9_480_ORIGINAL_WEIGHTED_BACKSLASH_VENDOR_RHS',...
 'release',version('-release'),'version',version,'original_unmodified',true,...
 'source_unseen',false,'n',480,'original_archived_first_w_run','43342252905',...
 'original_first_w_archive_sha256','229ca3f86046131854aca917f253e7c0861aded547992af81bbfda4e946fc49f',...
 'records',records);
outfile=getenv('WLS_480_OUTPUT');assert(~isempty(outfile));
fd=fopen(fullfile(root,outfile),'w');assert(fd>0);cleanup=onCleanup(@()fclose(fd));
fprintf(fd,'%s\n',jsonencode(out));
end
