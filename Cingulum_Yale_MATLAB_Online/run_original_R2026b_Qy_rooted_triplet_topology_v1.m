function run_original_R2026b_Qy_rooted_triplet_topology_v1()
% Exhaustive black-box *genuine* original MathWorks R2026b public Q' * y.
% Tests exact cancellations to infer the arithmetic addition reduction tree.
% This source probe discloses results and is RETROSPECTIVE for tree inference;
% it is NOT source-unseen independent Rust numeric parity.
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
data=jsondecode(fileread(fullfile(root,'matlab_Qy_reduction_triplet_topology_v1','input.json')));
assert(strcmp(data.schema,'ORIGINAL_MATHWORKS_R2026B_GEMV_EXHAUSTIVE_ROOTED_TRIPLE_CANCELLATION_TOPOLOGY_V1'));
N=numel(data.triples);assert(N==14155);
r0=struct('id','','n',0,'triple',zeros(1,3),'original_output_hex',{{}},...
  'repeated_original_source_bits_exact',false,'same_pair_across_output_columns',false);
records=repmat(r0,N,1);
M=2^54;assert(isequal(num2hex(M),'4350000000000000'));
for k=1:N
 c=data.triples(k);n=double(c.n);indexes=double(c.triple(:));a=indexes(1);b=indexes(2);d=indexes(3);
 assert(numel(indexes)==3&&a<b&&b<d&&d<=n&&n>=9&&n<=32);
 y=ones(n,1);
 Q1=zeros(n,2);
 Q1(a,1)=M;Q1(b,1)=-M;Q1(d,1)=1;
 Q1(a,2)=M;Q1(d,2)=-M;Q1(b,2)=1;
 Q2=zeros(n,2);
 Q2(b,1)=M;Q2(d,1)=-M;Q2(a,1)=1;
 Q2(a,2)=M;Q2(b,2)=-M;Q2(d,2)=1;
 out1=Q1'*y;out2=Q2'*y;
 assert(isequal(num2hex(out1),num2hex(Q1'*y))&&isequal(num2hex(out2),num2hex(Q2'*y)),...
 'True original MathWorks Qy was not bit-stable on repeat');
 val=[out1(:);out2(:)];
 assert(all(val==0|val==1),'Unexpected exact cancellation outcome');
 assert(isequal(num2hex(val),num2hex([out1;out2])));
 rec=r0;rec.id=c.id;rec.n=n;rec.triple=indexes(:)';
 rec.original_output_hex=cellstr(num2hex(val(:)))';
 rec.repeated_original_source_bits_exact=true;
 rec.same_pair_across_output_columns=isequal(num2hex(out1(1)),num2hex(out2(2)));
 records(k)=rec;
end
summary=struct();summary.original_MATLAB_release=version('-release');summary.cpu=computer;
summary.original_source_cases=N;
summary.exact_rooted_triplet_count=sum(arrayfun(@(r) (sum(strcmp(r.original_output_hex(1:3),'3ff0000000000000'))==1),records));
summary.same_pair_across_columns_count=sum([records.same_pair_across_output_columns]);
summary.original_source_repeats_all_identical=all([records.repeated_original_source_bits_exact]);
summary.MATLAB_ORIGINAL_GEMV_UNMODIFIED=true;
summary.original_source_results_disclosed_not_Rust_precommitted=true;
result=struct('classification','GENUINE_ORIGINAL_R2026B_14155_DENSE_ROOTED_TRIPLET_QTRANSPOSE_Y_ARITHMETIC_TREE_SOURCE_DISCLOSED',...
 'matlab_version',version,'matlab_release',version('-release'),'machine',computer,'MKL_CBWR',getenv('MKL_CBWR'),...
 'input_cases',N,'summary',summary,'records',records);
out=fullfile(root,'matlab_Qy_reduction_triplet_topology_v1','original_output.json');fid=fopen(out,'w');assert(fid>0);
fprintf(fid,'%s\n',jsonencode(result));fclose(fid);
fprintf('GENUINE_ORIGINAL_MATLAB_R2026B_TRIPLET_N=%d TREE_ONE_OF_THREE=%d SAME_PAIR_STABLE=%d SOURCE_REPEAT_EXACT=1\n',...
 N,summary.exact_rooted_triplet_count,summary.same_pair_across_columns_count);
end
