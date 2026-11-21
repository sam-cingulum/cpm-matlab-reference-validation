function run_scaled_probe
% Genuine original-only scientific diagnostic. No native Rust forecasts.
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);
input = strsplit(strtrim(fileread('probes.txt')), newline);
out = struct();
for rep = 1:2
    rows = cell(numel(input),1);
    for i = 1:numel(input)
        tokens = strsplit(strtrim(input{i}));
        x = hex2num(tokens{1}); a = hex2num(tokens{2});
        r = struct('x',tokens{1},'a',tokens{2});
        r.scaled_upper = num2hex(gammainc(x,a,'scaledupper'));
        r.scaled_lower = num2hex(gammainc(x,a,'scaledlower'));
        r.lower = num2hex(gammainc(x,a,'lower'));
        r.upper = num2hex(gammainc(x,a,'upper'));
        r.erfcx = num2hex(erfcx(sqrt(x)));
        r.erfc = num2hex(erfc(sqrt(x)));
        r.M_erfcx = num2hex(sqrt(pi*x)*erfcx(sqrt(x)));
        r.ratio = num2hex(a/x);
        % Source-only arithmetic association controls with the MATLAB
        % erfcx half-shape value: no hardcoded expected results.
        m = sqrt(pi*x)*erfcx(sqrt(x));
        if a == 0.5
            v = m*(0.5/x);
        else
            v = (m*0.5)/x;
            shape = 1.5;
            while shape < a
                v = ((1.0+v)*shape)/x;
                shape = shape+1.0;
            end
            v = (1.0+v)*(a/x);
        end
        r.erfcx_recurrence = num2hex(v);
        rows{i}=r;
    end
    out.repetitions(rep).rows = rows;
end
assert(isequal(out.repetitions(1),out.repetitions(2)));
out.commit=getenv('GITHUB_SHA');out.run=getenv('GITHUB_RUN_ID');
out.release=version;
fid=fopen('scaled_probe.json','w');assert(fid>=0);
fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
