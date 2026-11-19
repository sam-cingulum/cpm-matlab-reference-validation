function run_beta_odds_v32
assert(strcmp(version('-release'),'2026b') && contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);
assert(maxNumCompThreads == 1);
inputs = jsondecode(fileread('input.json'));
assert(~inputs.original_MATLAB_numeric_data_supplied && strcmp(inputs.source_unseen_V12,'NOT_GENERATED'));
for rep = 1:2
    rows = inputs.beta;
    for i = 1:numel(rows)
        a = hex2num(rows(i).a_hex);
        b = hex2num(rows(i).b_hex);
        x = hex2num(rows(i).x_hex);
        rows(i).lower_hex = num2hex(betainc(x,a,b,'lower'));
        rows(i).upper_hex = num2hex(betainc(x,a,b,'upper'));
    end
    output.repetitions(rep).rows = rows;
end
assert(isequal(output.repetitions(1),output.repetitions(2)));
output.release = version;
output.run = getenv('GITHUB_RUN_ID');
output.commit = getenv('GITHUB_SHA');
fid = fopen('original.json','w');
assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(output));
assert(fclose(fid)==0);
end
