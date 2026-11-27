function run_v1421()
% V1421 source-disclosed diagnostic (a probe, not a firstblind; the V1420 harness with symmetric
% inputs and chol added): MATLAB's own X\B for square symmetric A (cases.csv: case,seed,kind,n,p,k,mod). For each case, twice: the inputs A and B
% (written out, so nothing has to regenerate them), returned or the error (identifier and
% text), X = A\B, the residual B - A*X, and for square A [L,U,P] = lu(A) and rcond(A), for wide A
% [~,R,E] = qr(A,0), each with MATLAB's size and class; the text A\B prints and the last warning
% A\B leaves. No MEX, no twin, no Rust output.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
for fn={'mldivide','lu','rcond','qr','chol','rng','rand','triu','tril','sort','eye','zeros'}
 assert(startsWith(which(fn{1}),matlabroot)||contains(which(fn{1}),'built-in'),'%s is shadowed',fn{1});
end
outdir=fullfile(root,'out');if ~exist(outdir,'dir');mkdir(outdir);end
warning('off','backtrace');
lines=strsplit(strtrim(fileread(fullfile(root,'cases.csv'))),newline);
assert(strcmp(strtrim(lines{1}),'case,seed,kind,n,p,k,mod'));
fi=fopen(fullfile(outdir,'bb_in.bin'),'w','ieee-le');
fif=fopen(fullfile(outdir,'bb_in_fields.csv'),'w');
o=[fopen(fullfile(outdir,'bb.bin'),'w','ieee-le'),fopen(fullfile(outdir,'bb_repeat.bin'),'w','ieee-le')];
ff=[fopen(fullfile(outdir,'bb_fields.csv'),'w'),fopen(fullfile(outdir,'bb_fields_repeat.csv'),'w')];
fs=[fopen(fullfile(outdir,'bb_status.tsv'),'w'),fopen(fullfile(outdir,'bb_status_repeat.tsv'),'w')];
ft=[fopen(fullfile(outdir,'bb_text.tsv'),'w'),fopen(fullfile(outdir,'bb_text_repeat.tsv'),'w')];
for li=2:numel(lines)
 f=strsplit(strtrim(lines{li}),',','CollapseDelimiters',false);
 assert(numel(f)==7,'bad case line %s',lines{li});
 c=str2double(f{1});seed=str2double(f{2});kind=f{3};n=str2double(f{4});p=str2double(f{5});
 k=str2double(f{6});mods=f{7};
 [A,B]=makedata(seed,n,p,k,mods);
 ins={A,B};inn={'A','B'};
 for j=1:2
  v=ins{j};fwrite(fi,typecast(double(v(:)),'uint64'),'uint64');
  fprintf(fif,'%d,%s,%d,%d,%s\n',c,inn{j},size(v,1),size(v,2),class(v));
 end
 for rep=1:2
  X=[];ME=[];ok=false; %#ok<NASGU>
  lastwarn('','');
  txt=evalc('try;X=A\B;ok=true;catch ME;ok=false;end');
  [lm,lid]=lastwarn;
  names={};vals={};
  if ok
   Res=B-A*X;
   names={'X','Res'};vals={X,Res};
   switch kind
    case 'sq'
     [L,U,P]=lu(A);rc=rcond(A);[Rc,flag]=chol(A);
     names=[names,{'L','U','P','rc','Rc','flag'}];vals=[vals,{L,U,P,rc,Rc,flag}];
    case 'wd'
     [~,R,E]=qr(A,0);
     names=[names,{'R','E'}];vals=[vals,{R,E}];
    otherwise;error('bad kind %s',kind);
   end
  end
  for j=1:numel(vals)
   v=vals{j};
   fwrite(o(rep),typecast(double(v(:)),'uint64'),'uint64');
   fprintf(ff(rep),'%d,%s,%d,%d,%s\n',c,names{j},size(v,1),size(v,2),class(v));
  end
  if ok
   fprintf(fs(rep),'%d\treturned\t-\t-\t%s\t%s\n',c,dash(lid),dash(lm));
  else
   fprintf(fs(rep),'%d\terror\t%s\t%s\t%s\t%s\n',c,dash(ME.identifier),dash(ME.message),dash(lid),dash(lm));
  end
  fprintf(ft(rep),'%d\t%s\n',c,hexbytes(txt));
 end
 fprintf('case %d done\n',c);
end
fclose('all');
prov=struct('classification','V1421_SOURCE_DISCLOSED_SYMMETRIC_MLDIVIDE_PROBE','V12','SEALED', ...
 'release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
 'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'),'public_commit',getenv('GITHUB_SHA'), ...
 'cases',numel(lines)-1);
[~,t]=system('lscpu');prov.lscpu=t;
h=fopen(fullfile(outdir,'provenance.json'),'w');assert(h>0);fprintf(h,'%s\n',jsonencode(prov));fclose(h);
end

function [A,B]=makedata(seed,n,p,k,mods)
rng(seed,'twister');
R=rand(n,p)-0.5;B=rand(n,k)-0.5;
A=R+R.';
switch mods
 case 'sym'
 case 'symdom';A(1:n+1:end)=n+1;
 case 'sympos';d=abs(diag(A))+0.01;A(1:n+1:end)=d;
 case 'symneg';A(1:n+1:end)=-(n+1);
 case 'onesym';A(:,1)=1;A(1,:)=1;
 otherwise;error('bad mod %s',mods);
end
assert(isequal(A,A.'));
end

function s=dash(s)
if isstring(s);s=char(s);end
s=regexprep(s,'[\t\r\n]',' ');if isempty(s);s='-';end
end

function s=hexbytes(t)
s=sprintf('%02x',uint8(char(t)));if isempty(s);s='00';end
end
