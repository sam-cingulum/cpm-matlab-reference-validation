function run_original_R2026b_Blas_Qy_reduction_microprobe_v1()
% Genuine original MathWorks R2026b black-box BLAS Q' * y numerical forensics.
% Original public MathWorks matrix multiplication, not a replacement oracle.
% Source not patched or disassembled; all test inputs independent exact hex.
% Previously established original robustfit st.Qy==pivot_restored(Q'*y)
% across 480/480 original source fits on each of four separate AMD hosts.
assert(strcmp(version('-release'),'2026b'));
root=fileparts(mfilename('fullpath'));
D=jsondecode(fileread(fullfile(root,'matlab_Qy_blas_reduction_microprobe_v1','input.json')));
assert(strcmp(D.schema,'AUTHENTIC_ORIGINAL_MATHWORKS_R2026B_BLAS_GEMV_Qtranspose_Y_REDUCTION_TREE_MICROPROBE_V1'));
N=numel(D.cases);assert(N==3610);
record=struct('id',{},'n',{},'scenario',{},'original_public_Qy_hex',{},'repeat_bitwise_exact',{});
for k=1:N
 % Heterogeneous record fields (cancellation additive_terms versus random)
 % intentionally cause jsondecode to return a cell array, not struct array.
 if iscell(D.cases),c=D.cases{k};else,c=D.cases(k);end
 n=double(c.n);
 Q=hex2num(char(c.Q_hex));Q=reshape(Q,n,2);y=hex2num(char(c.y_hex));y=y(:);
 assert(n>=9 && n<=128 && numel(y)==n && numel(Q)==n*2);
 assert(all(strcmp(cellstr(num2hex(Q(:))),cellstr(char(c.Q_hex)))));
 assert(all(strcmp(cellstr(num2hex(y(:))),cellstr(char(c.y_hex)))));
 qy=Q'*y;
 qy_again=Q'*y;
 assert(isequal(num2hex(qy),num2hex(qy_again)),"original public GEMV numeric repeat differed");
 r=struct();r.id=c.id;r.n=n;r.scenario=c.scenario;
 r.original_public_Qy_hex=cellstr(num2hex(qy(:)))';r.repeat_bitwise_exact=true;
 record(end+1)=r; %#ok<AGROW>
end
assert(numel(record)==3610 && all([record.repeat_bitwise_exact]));
result=struct('classification','UNMODIFIED_ORIGINAL_MATHWORKS_R2026B_GEMV_REDUCTION_TREE_NUMERICAL_MICROPROBE',...
 'matlab_version',version,'matlab_release',version('-release'),'architecture',computer,'MKL_CBWR',getenv('MKL_CBWR'),...
 'original_mtimes_unmodified',true,'original_binary64_every_run_repeat_bitwise_exact',true,...
 'original_input_sha256_in_github_workflow',true,'cases',N,'source_blind_Rust_Qy_prediction_precommitted',false,...
 'reference_is_genuine_original_MathWorks_MATLAB',true,'records',record);
out=fullfile(root,'matlab_Qy_blas_reduction_microprobe_v1','original_output.json');
fid=fopen(out,'w');assert(fid>0);fprintf(fid,'%s\n',jsonencode(result));fclose(fid);
fprintf('AUTHENTIC_ORIGINAL_MATLAB_R2026B_Qy_MICROPROBE N=%d arithmetic_output_double_elements=%d normal_exit=1\n',N,2*N);
end
