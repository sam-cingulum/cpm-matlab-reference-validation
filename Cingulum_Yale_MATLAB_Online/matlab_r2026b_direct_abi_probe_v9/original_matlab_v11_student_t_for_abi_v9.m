function original_matlab_v11_student_t_for_abi_v9
% Authorized genuine MathWorks R2026b oracle on SHA-frozen native Rust INPUTS.
% This does not calculate any t,dfe from original MATLAB robustfit.
% It evaluates 2*tcdf(-abs(t),df) from independent source-disclosed pure Rust.
assert(strcmp(version('-release'),'2026b'),'Requires real R2026b');
root=fileparts(mfilename('fullpath'));
D=jsondecode(fileread(fullfile(root,'frozen_v11_independent_rust_t_dfe_input.json')));
assert(D.raw_case_count==480 && D.coefficient_count==960);
assert(~D.original_MATLAB_reference_numeric_values_used_to_generate);
fid=fopen(fullfile(root,'original_v11_p_from_rust_t_v9.txt'),'w');
assert(fid>0);
for i=1:480
    row=D.rows(i);
    dfh=char(row.dfe_hex);
    df=hex2num(dfh);
    for j=1:2
        if iscell(row.t_hex)
            th=char(row.t_hex{j});
        else
            th=char(row.t_hex(j));
        end
        t=hex2num(th);
        value=2*tcdf(-abs(t),df);
        fprintf(fid,'T %s %d %s %s %s\n',char(row.id),j,th,dfh,num2hex(value));
    end
end
fclose(fid);
fprintf('ORIGINAL_R2026B_TCDF_960_COEFFICIENTS_FROM_INDEPENDENT_RUST_T_DFE_DONE\n');
end
