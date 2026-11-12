function qr_runtime_probe_v1()
% Two real MathWorks QR operations. Dynamic loader audit is passive.
assert(strcmp(version('-release'),'2026b'));
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
d=jsondecode(fileread(fullfile(root,'robustfit_raw_full_source_unseen_v1','input.json')));
assert(numel(d.cases)==48);
for k=[1 2 7 13 24 48]
 c=d.cases(k);x=double(c.x(:));y=double(c.y(:));
 [~,R,p]=qr([ones(numel(x),1),x],'econ','vector');
 [~,st]=robustfit(x,y);
 fprintf('QR_AUDIT_CASE %s R12=%s R22=%s SOURCE_R12=%s PIVOT=%d,%d\n',...
  c.id,num2hex(R(1,2)),num2hex(R(2,2)),num2hex(st.R(1,2)),p(1),p(2));
end
end
