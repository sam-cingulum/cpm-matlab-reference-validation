function report=run_qr_householder_arithmetic_retrospective_v1()
% Public, source-free API arithmetic diagnostics on 48 ALREADY disclosed raw
% synthetic inputs. Not a prospective, independent-native source certificate.
% Q and Rp are genuine MATLAB public qr API outputs, not extracted source.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
root=fileparts(mfilename('fullpath'));
data=jsondecode(fileread(fullfile(root,'robustfit_raw_full_source_unseen_v1','input.json')));
assert(numel(data.cases)==48);
names={'q_matmul','q_dot','q_sum','raw_dot_over_beta',...
 'raw_matmul_over_beta','raw_sum_over_beta','raw_sum_then_div',...
 'householder_matmul','householder_dot','householder_sum',...
 'householder_three_term','householder_fused_vector','raw_norm'};
counts=zeros(1,numel(names));
rec=cell(48,1);
for k=1:48
 c=data.cases(k);x=double(c.x(:));X=[ones(numel(x),1),x];
 [Q,Rp,piv]=qr(X,'econ','vector');
 beta=Rp(1,1);target=Rp(1,2);
 first=X(:,piv(1));second=X(:,piv(2));
 rawcross=first.*second;
 rawscore=first'*second;
 ratio=first./beta;
 alpha=first(1);v=[1; first(2:end)./(alpha-beta)];
 tau=(beta-alpha)/beta;
 fact= v'*second;
 % Mathematical similarity does not imply binary64 identity.
 vals=[Q(:,1)'*second, dot(Q(:,1),second), sum(Q(:,1).*second),...
  dot(first,second)/beta, rawscore/beta,...
  sum(rawcross)/beta, sum(rawcross./beta),...
  second(1)-tau*fact, second(1)-tau*dot(v,second),...
  second(1)-tau*sum(v.*second),...
  second(1)-tau*(second(1)+sum(v(2:end).*second(2:end))),...
  (second-tau*v*(v'*second))'*[1;zeros(numel(x)-1,1)],...
  -sign(alpha)*norm(first)];
 cmp=cell(1,numel(names));exact=zeros(1,numel(names));
 for j=1:numel(names)
  value=vals(j);
  if j==numel(names),orig=beta;else,orig=target;end
  cmp{j}=num2hex(value);
  exact(j)=strcmp(cmp{j},num2hex(orig));
  counts(j)=counts(j)+exact(j);
 end
 rec{k}=struct('id',c.id,'n',numel(x),'pivot',double(piv(:)'),...
  'source_R11_hex',num2hex(beta),'source_R12_hex',num2hex(target),...
  'candidate_hex',{cmp},'exact',logical(exact));
end
[~,cpu]=system('grep -m 1 "model name" /proc/cpuinfo');
report=struct('status','RETROSPECTIVE_QR_HOUSEHOLDER_PUBLIC_MATLAB_API_ARITHMETIC',...
 'original_source_unmodified',true,'not_prospective',true,...
 'release',version('-release'),'matlab_version',version,...
 'cpu',strtrim(cpu),'github_sha',getenv('GITHUB_SHA'),...
 'github_run_id',getenv('GITHUB_RUN_ID'),...
 'mkl_cbwr',getenv('MKL_CBWR'),'max_threads',maxNumCompThreads,...
 'cases',48,'candidate_names',{names},'exact_case_counts',counts,...
 'records',{rec});
out=fullfile(root,'native_qr_retro_same_runner_v1','matlab_householder_arithmetic_original_api.json');
assert(~exist(out,'file'));
fid=fopen(out,'w');assert(fid>0);cl=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
for j=1:numel(names)
 fprintf('MATLAB_HOUSEHOLDER_CANDIDATE_%s %d/48\n',names{j},counts(j));
end
end
