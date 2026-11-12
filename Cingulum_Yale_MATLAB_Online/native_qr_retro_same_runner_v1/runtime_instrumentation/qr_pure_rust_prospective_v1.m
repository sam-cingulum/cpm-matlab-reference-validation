function qr_pure_rust_prospective_v1()
% Prospective original MathWorks QR oracle. Rust prediction commit 412ecf9
% was frozen and pushed BEFORE this MATLAB source invocation.
assert(strcmp(version('-release'),'2026b'));
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
p=fileparts(mfilename('fullpath'));
d=jsondecode(fileread(fullfile(root,'qr_pure_rust_prospective_v1','input.json')));
assert(numel(d.cases)==72);
records=struct('id',{},'iteration',{},'R_hex',{},'pivot',{});
for iter=1:3
 for k=1:72
  c=d.cases(k);x=double(c.x(:));
  [~,R,pivot]=qr([ones(numel(x),1),x],'econ','vector');
  rec.id=c.id;rec.iteration=iter;
  rec.R_hex=cellstr(num2hex(R(:)));rec.pivot=pivot;
  records(end+1)=rec; %#ok<AGROW>
  fprintf('QR_UNSEEN_CASE %d %s P=%d,%d R11=%s R12=%s R22=%s\n',iter,c.id,pivot(1),pivot(2),num2hex(R(1,1)),num2hex(R(1,2)),num2hex(R(2,2)));
 end
end
result.release=version('-release');result.matlab_version=version;
result.computer=computer;result.records=records;
out=getenv('QR_UNSEEN_OUTPUT');assert(~isempty(out));
fid=fopen(fullfile(p,out),'w');assert(fid>0);
fprintf(fid,'%s',jsonencode(result));fclose(fid);
end
