function qr_native_qy_original_480_v4()
% Truly prospective original MathWorks R2026b QR / robustfit oracle.
% Independent compiled pure-Rust binary64 forecast committed and pushed at
% private Cingulum CPM SHA 2040f2b8b93149faf0d4fe8a0d8acf763f5ac358.
% Run this script only AFTER verifying frozen independent Rust predictions.
assert(strcmp(version('-release'),'2026b'),'incorrect MathWorks release');
p=fileparts(mfilename('fullpath'));
root=fileparts(fileparts(p));
raw=jsondecode(fileread(fullfile(root,'matlab_qy_native_tree_source_unseen_480_v4','input.json')));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_SOURCE_UNSEEN_NATIVE_QY_12_DUAL_TREES_480_V4'));
assert(numel(raw.cases)==480);
records=struct('id',{},'iteration',{},'n',{},'pivot',{},'R_hex',{},'Q_hex',{},'Q_rowsquare_h_hex',{},'robustfit_ok',{},'robustfit_error',{},'source_R_hex',{},'source_h_hex',{},'source_beta_hex',{},'source_numeric_stats',{});
for iteration=1:3
 for k=1:numel(raw.cases)
  c=raw.cases(k);
  x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
  x=x(:);y=y(:);n=numel(x);
  assert(n==double(c.n) && numel(y)==n && n>=9 && n<=128);
  assert(all(strcmp(cellstr(num2hex(x)),cellstr(char(c.x_hex)))));
  assert(all(strcmp(cellstr(num2hex(y)),cellstr(char(c.y_hex)))));
  [Q,R,pivot]=qr([ones(n,1),x],'econ','vector');
  rec.id=c.id;rec.iteration=iteration;rec.n=n;rec.pivot=pivot;
  rec.R_hex=cellstr(num2hex(R(:)));
  rec.Q_hex=cellstr(num2hex(Q(:)));
  rec.Q_rowsquare_h_hex=cellstr(num2hex(sum(Q.^2,2)));
  rec.robustfit_ok=true;rec.robustfit_error='';
  rec.source_R_hex={};rec.source_h_hex={};rec.source_beta_hex={};rec.source_numeric_stats=struct();
  try
   [b,st]=robustfit(x,y);
   rec.source_R_hex=cellstr(num2hex(st.R(:)));
   rec.source_h_hex=cellstr(num2hex(st.h(:)));
   rec.source_beta_hex=cellstr(num2hex(b(:)));
   names=fieldnames(st);results=struct();
   for t=1:numel(names)
    name=names{t};v=st.(name);
    if isa(v,'double') && isreal(v)
     entry=struct();entry.shape=size(v);
     entry.hex=cellstr(num2hex(v(:)));
     results.(name)=entry;
    end
   end
   rec.source_numeric_stats=results;
  catch ME
   rec.robustfit_ok=false;
   rec.robustfit_error=sprintf('%s:%s',ME.identifier,ME.message);
  end
  records(end+1)=rec; %#ok<AGROW>
  fprintf('UNSEEN_Q_LEVERAGE_ORIGINAL_SOURCE_ORACLE case=%s iter=%d n=%d r11=%s r12=%s r22=%s robust=%d\n',c.id,iteration,n,num2hex(R(1,1)),num2hex(R(1,2)),num2hex(R(2,2)),rec.robustfit_ok);
 end
end
result=struct();result.matlab_release=version('-release');result.version=version;
result.computer=computer;result.mkl_cbwr=getenv('MKL_CBWR');
result.input_case_count=numel(raw.cases);result.records=records;
out=getenv('QR_NATIVE_QY_480_OUTPUT');assert(~isempty(out));
fid=fopen(fullfile(p,out),'w');assert(fid>0);
fprintf(fid,'%s',jsonencode(result));fclose(fid);
end
