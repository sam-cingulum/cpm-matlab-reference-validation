function run_v1310()
% V1310 original-only firstblind X\B.
% Reads the frozen synthetic input container only (CPMMLI01: magic, uint64 case count, then
% per case uint64 rows, cols, width and the column-major doubles of X and B) and writes what
% genuine MATLAB returns for X\B, twice. No MEX, no Rust forecast, no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
names={'hidden.bin','hidden_repeat.bin'};
ranks=cell(1,2);
words=0;
for rep=1:2
 f=fopen(fullfile(root,'input.bin'),'r','ieee-le');assert(f>0);
 magic=fread(f,8,'uint8=>char')';assert(strcmp(magic,'CPMMLI01'));
 n=fread(f,1,'uint64');
 o=fopen(fullfile(outdir,names{rep}),'w','ieee-le');assert(o>0);
 r=zeros(n,5);
 words=0;
 for i=1:n
  d=fread(f,3,'uint64');m=d(1);p=d(2);w=d(3);
  X=reshape(fread(f,m*p,'double'),m,p);
  B=reshape(fread(f,m*w,'double'),m,w);
  lastwarn('');
  H=X\B;
  [wm,wid]=lastwarn;
  rk=p;
  if ~isempty(wm)
   assert(strcmp(wid,'MATLAB:rankDeficientMatrix'),'unexpected warning %s: %s',wid,wm);
   t=regexp(wm,'rank = (\d+)','tokens','once');
   rk=str2double(t{1});
  end
  assert(isequal(size(H),[p w]));
  fwrite(o,H(:),'double');
  words=words+p*w;
  r(i,:)=[i-1 m p w rk];
 end
 assert(isempty(fread(f,1,'uint8')));
 fclose(f);fclose(o);
 ranks{rep}=r;
end
assert(isequal(ranks{1},ranks{2}));
writematrix(ranks{1},fullfile(outdir,'hidden_ranks.csv'));
prov=struct('classification','V1310_ORIGINAL_ONLY_MLDIVIDE_FIRSTBLIND','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false,'cases',n,'words',words, ...
 'rank_deficient_cases',sum(ranks{1}(:,5)<ranks{1}(:,3)));
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(prov));
fclose(f);
end
