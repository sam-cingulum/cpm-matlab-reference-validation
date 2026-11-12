function qr_control_v2()
assert(strcmp(version('-release'),'2026b'));
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
p=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'robustfit_raw_full_source_unseen_v1','input.json')));
assert(numel(d.cases)==48);
ids=[1 2 7 13 24 48];
records=struct('id',{},'iteration',{},'R_hex',{},'source_R_hex',{},'source_h_hex',{},'pivot',{},'source_equal_public',{});
for iter=1:3
 for k=ids
  c=d.cases(k);x=double(c.x(:));y=double(c.y(:));
  [~,R,pivot]=qr([ones(numel(x),1),x],'econ','vector');
  [~,st]=robustfit(x,y);
  rec.id=c.id;rec.iteration=iter;
  rec.R_hex=cellstr(num2hex(R(:)));rec.source_R_hex=cellstr(num2hex(st.R(:)));
  rec.source_h_hex=cellstr(num2hex(st.h(:)));rec.pivot=pivot;
  rec.source_equal_public=isequal(R,st.R);
  records(end+1)=rec; %#ok<AGROW>
  fprintf('QR_CONTROL_CASE %d %s R12=%s R22=%s SOURCE_R12=%s EQUAL=%d\n',iter,c.id,num2hex(R(1,2)),num2hex(R(2,2)),num2hex(st.R(1,2)),rec.source_equal_public);
 end
end
result.release=version('-release');result.matlab_version=version;
result.computer=computer;result.mkl_cbwr=getenv('MKL_CBWR');result.mkl_threads=getenv('MKL_NUM_THREADS');
result.omp_threads=getenv('OMP_NUM_THREADS');result.records=records;
out=getenv('QR_CONTROL_OUTPUT');
if isempty(out);out='qr_control_v2.json';end
fid=fopen(fullfile(p,out),'w');assert(fid>0);
fprintf(fid,'%s',jsonencode(result));fclose(fid);
end
