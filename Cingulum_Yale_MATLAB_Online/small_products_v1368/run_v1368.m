function run_v1368()
% V1368 source-disclosed diagnostic (not evidence for any certificate). V1365/V1366 fitted
% MATLAB's Z'*Z (MKL syrk) from 256 rows up. V1364 missed on PCA folds with 9 and 10 training
% rows, and the distinct-operand products CPM uses were never probed at small shapes. On
% genuine MATLAB R2026b Update 1, for every shape (L rows, w columns) below:
%   G = Z'*Z (upper triangle), c = Z'*y, p = Z*b, H = Z'*Y (full), d = y'*Z (row)
% with Z = rand(L,w)-0.5, y = rand(L,1)-0.5, b = rand(w,1)-0.5, Y = rand(L,w)-0.5 drawn in that
% order after rng(seed,'twister'). Synthetic seeded inputs only. Reads no Rust forecast and no
% earlier MATLAB output. V12 SEALED.
% products.bin: 'CPMGD001'; per case u64 [case seed L w], then G(up) column by column
% (for j = 1..w, G(1:j,j)), c (w), p (L), H(:) column-major (w*w), d (w).
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
logf=fopen(fullfile(outdir,'log.txt'),'w');assert(logf>0);
closeLog=onCleanup(@()fclose(logf));
prov=struct('classification','V1368_SOURCE_DISCLOSED_SMALL_PRODUCTS_DIAGNOSTIC','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'),'mkl_cbwr',getenv('MKL_CBWR'), ...
 'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'),'forecast_read',false);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');fprintf(h,'%s\n',jsonencode(prov));fclose(h);
tStart=tic;
shapes=zeros(0,2);
for L=2:40;for w=1:30;shapes(end+1,:)=[L w];end;end %#ok<AGROW>
for L=[48 63 64 65 96 127 128 129 160 191 192 193 200 255 256]
 for w=[1:30 40 64 65 77];shapes(end+1,:)=[L w];end %#ok<AGROW>
end
for L=2:40;for w=[40 64 65 77 131];shapes(end+1,:)=[L w];end;end %#ok<AGROW>
f=fopen(fullfile(outdir,'products.bin'),'w','ieee-le');assert(f>0);fwrite(f,'CPMGD001','char');
fc=fopen(fullfile(outdir,'products_cases.csv'),'w');fprintf(fc,'case,seed,L,w\n');
for c=0:size(shapes,1)-1
 L=shapes(c+1,1);w=shapes(c+1,2);
 seed=136800000+c;
 rng(seed,'twister');
 Z=rand(L,w)-0.5;y=rand(L,1)-0.5;b=rand(w,1)-0.5;Y=rand(L,w)-0.5;
 G=Z'*Z;cc=Z'*y;p=Z*b;H=Z'*Y;d=y'*Z;
 up=triu(true(w));
 fwrite(f,uint64([c seed L w]),'uint64');
 fwrite(f,typecast([G(up);cc;p;H(:);d(:)],'uint64'),'uint64');
 fprintf(fc,'%d,%d,%d,%d\n',c,seed,L,w);
end
fclose(f);fclose(fc);
fprintf(logf,'cases %d t=%.1f\n',size(shapes,1),toc(tStart));
end
