function run_v1354()
% V1354 original-only firstblind: X\B and robustfit with 131..2,000 rows.
% Reads the two frozen synthetic input containers only and writes what genuine MATLAB returns,
% twice each:
%  xb  input_xb.bin (CPMMLI01: magic, uint64 case count, then per case uint64 rows, cols, width
%      and the column-major doubles of X and B): H = X\B;
%  rf  input_rf.bin (CPMRFI01: magic, uint64 case count, then per case uint64 rows, predictors
%      and the column-major doubles of X and of y): [b, stats] = robustfit(X, y), b and all 17
%      stats fields.
% Every warning is recorded word for word: evalc captures each printed warning (MATLAB wraps
% long ones on display, so line breaks inside a message become spaces again) and lastwarn gives
% the identifier and text of the last one, which must equal the last captured message.
% No MEX, no twin, no Rust forecast, no earlier MATLAB output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
outdir=fullfile(root,'out');
if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
fields={'ols_s','robust_s','mad_s','s','resid','rstud','se','covb','coeffcorr','t','p','w','Qy','R','dfe','h','Rtol'};
prov=struct('classification','V1354_ORIGINAL_ONLY_LARGE_ROWS_FIRSTBLIND','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'forecast_read',false);
for s={'xb','rf'}
 s=s{1}; %#ok<FXSET>
 names={['hidden_' s '.bin'],['hidden_' s '_repeat.bin']};
 metas=cell(1,2);warns=cell(1,2);
 for rep=1:2
  f=fopen(fullfile(root,['input_' s '.bin']),'r','ieee-le');assert(f>0);
  magic=fread(f,8,'uint8=>char')';
  nc=fread(f,1,'uint64');
  o=fopen(fullfile(outdir,names{rep}),'w','ieee-le');assert(o>0);
  meta=zeros(nc,5);wl={};words=0;
  for i=1:nc
   if strcmp(s,'xb')
    assert(strcmp(magic,'CPMMLI01'));
    d=fread(f,3,'uint64');m=d(1);p=d(2);w=d(3);
    X=reshape(fread(f,m*p,'double'),m,p);
    B=reshape(fread(f,m*w,'double'),m,w);
    lastwarn('','');
    txt=evalc('H=X\B;');
    [lm,lid]=lastwarn;
    assert(isequal(size(H),[p w]));
    fwrite(o,H(:),'double');words=words+p*w;
    rk=p;
    if ~isempty(lid)
     assert(strcmp(lid,'MATLAB:rankDeficientMatrix'),'unexpected warning %s: %s',lid,lm);
     t=regexp(lm,'rank = (\d+)','tokens','once');rk=str2double(t{1});
    end
    meta(i,:)=[i-1 m p w rk];
   else
    assert(strcmp(magic,'CPMRFI01'));
    d=fread(f,2,'uint64');n=d(1);k=d(2);p=k+1;
    X=reshape(fread(f,n*k,'double'),n,k);
    y=fread(f,n,'double');
    lastwarn('','');
    txt=evalc('[b,st]=robustfit(X,y);');
    [lm,lid]=lastwarn;
    assert(isequal(size(b),[p 1]));
    assert(isequal(fieldnames(st)',fields));
    fwrite(o,b(:),'double');words=words+p;
    for q=1:numel(fields)
     v=double(st.(fields{q}));fwrite(o,v(:),'double');words=words+numel(v);
    end
    meta(i,:)=[i-1 n k n-st.dfe 0];
   end
   msgs=captured(txt);
   if isempty(lid)
    assert(isempty(msgs),'case %d: evalc captured a warning that lastwarn did not report',i-1);
   else
    assert(~isempty(msgs)&&strcmp(msgs{end},lm),'case %d: the last captured warning differs from lastwarn',i-1);
   end
   for q=1:numel(msgs)
    id='-';if q==numel(msgs);id=lid;end
    wl{end+1}=sprintf('%d\t%s\t%s',i-1,id,msgs{q}); %#ok<AGROW>
    if strcmp(s,'rf')&&strcmp(msgs{q},'Iteration limit reached.');meta(i,5)=1;end
   end
  end
  assert(isempty(fread(f,1,'uint8')));
  fclose(f);fclose(o);
  metas{rep}=meta;warns{rep}=wl;
 end
 assert(isequal(metas{1},metas{2}),'the two %s repetitions differ in meta',s);
 assert(isequal(warns{1},warns{2}),'the two %s repetitions differ in warnings',s);
 writematrix(metas{1},fullfile(outdir,['hidden_' s '_meta.csv']));
 f=fopen(fullfile(outdir,['hidden_' s '_warnings.tsv']),'w');assert(f>0);
 for q=1:numel(warns{1});fprintf(f,'%s\n',warns{1}{q});end
 fclose(f);
 prov.([s '_cases'])=nc;prov.([s '_words'])=words;prov.([s '_warnings'])=numel(warns{1});
end
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
