function run_v1357()
% V1357 original-only firstblind: X\B with many right-hand sides (41..71,825).
% Reads the frozen case list only (cases.csv: case,seed,rows,cols,width,kind) and regenerates
% each synthetic system with MATLAB's own generator:
%   rng(seed,'twister'); X = rand(rows,cols) - 0.5; B = rand(rows,width) - 0.5;
%   kind 1: X(:,cols) = X(:,1) + X(:,2)   (rank deficient)
% then writes what genuine MATLAB returns for H = X\B, computed twice per case (the two
% repetitions must agree bit for bit). Every warning is recorded word for word: evalc captures
% each printed warning (display wrapping undone) and lastwarn gives the identifier and text of
% the last one. No MEX, no twin, no Rust forecast, no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
f=fopen(fullfile(root,'cases.csv'),'r');assert(f>0);
head=fgetl(f);assert(strcmp(head,'case,seed,rows,cols,width,kind'));
C=textscan(f,'%f%f%f%f%f%f','Delimiter',',');fclose(f);
C=[C{:}];nc=size(C,1);assert(isequal(C(:,1)',0:nc-1));
o1=fopen(fullfile(outdir,'hidden.bin'),'w','ieee-le');assert(o1>0);
o2=fopen(fullfile(outdir,'hidden_repeat.bin'),'w','ieee-le');assert(o2>0);
fm=fopen(fullfile(outdir,'hidden_meta.csv'),'w');assert(fm>0);
fw=fopen(fullfile(outdir,'hidden_warnings.tsv'),'w');assert(fw>0);
words=0;nwarn=0;
for i=1:nc
 seed=C(i,2);m=C(i,3);n=C(i,4);w=C(i,5);kind=C(i,6);
 rng(seed,'twister');
 X=rand(m,n)-0.5;B=rand(m,w)-0.5;
 if kind==1;X(:,n)=X(:,1)+X(:,2);end
 runs=cell(1,2);ids=cell(1,2);txts=cell(1,2);lms=cell(1,2);
 for rep=1:2
  lastwarn('','');
  txt=evalc('H=X\B;');
  [lm,lid]=lastwarn;
  assert(isequal(size(H),[n w]));
  runs{rep}=typecast(H(:),'uint64');ids{rep}=lid;txts{rep}=txt;lms{rep}=lm;
 end
 assert(isequal(runs{1},runs{2}),'case %d: the two repetitions differ',i-1);
 assert(strcmp(ids{1},ids{2})&&strcmp(txts{1},txts{2}),'case %d: warnings differ between repetitions',i-1);
 fwrite(o1,runs{1},'uint64');fwrite(o2,runs{2},'uint64');words=words+n*w;
 rk=n;lid=ids{1};lm=lms{1};
 if ~isempty(lid)
  assert(strcmp(lid,'MATLAB:rankDeficientMatrix'),'unexpected warning %s: %s',lid,lm);
  t=regexp(lm,'rank = (\d+)','tokens','once');rk=str2double(t{1});
 end
 fprintf(fm,'%d,%d,%d,%d,%d,%d\n',i-1,m,n,w,kind,rk);
 msgs=captured(txts{1});
 if isempty(lid)
  assert(isempty(msgs),'case %d: evalc captured a warning that lastwarn did not report',i-1);
 else
  assert(~isempty(msgs)&&strcmp(msgs{end},lm),'case %d: the last captured warning differs from lastwarn',i-1);
 end
 for q=1:numel(msgs)
  id='-';if q==numel(msgs);id=lid;end
  fprintf(fw,'%d\t%s\t%s\n',i-1,id,msgs{q});nwarn=nwarn+1;
 end
 clear X B H runs
end
fclose(o1);fclose(o2);fclose(fm);fclose(fw);
prov=struct('classification','V1357_ORIGINAL_ONLY_WIDE_RHS_FIRSTBLIND','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false,'cases',nc,'words',words,'warnings',nwarn);
[~,t]=system('lscpu');prov.lscpu=t;
f=fopen(fullfile(outdir,'provenance.json'),'w');assert(f>0);
fprintf(f,'%s\n',jsonencode(prov));
fclose(f);
end

function msgs=captured(txt)
% The warnings evalc captured, in order: '[<BS>Warning: <message>]<BS>' and a line break, with
% MATLAB's display wrapping undone.
txt=strrep(txt,char(8),'');
tok=regexp(txt,'\[Warning: (.*?)\] ?\n','tokens');
msgs=cellfun(@(c)strrep(c{1},newline,' '),tok,'UniformOutput',false);
end
