function report = run_robustfit_repeatability_v1()
% Genuine MathWorks R2026b black-box reproducibility, with frozen inputs.
% No proprietary MathWorks source copied. No frozen forecast read.
assert(exist('OCTAVE_VERSION','builtin') == 0);
assert(strcmp(version('-release'),'2026b'));
root = fileparts(mfilename('fullpath'));
base = fullfile(root,'robustfit_source_fd_prospective_v1');
m = jsondecode(fileread(fullfile(base,'manifest.json')));
data = jsondecode(fileread(fullfile(base,'input.json')));
assert(strcmp(m.experiment_id,'mathworks-robustfit-source-fd-prospective-20261111-v1'));
assert(m.samples == 24 && numel(data.samples) == 24 && m.source_not_run);
[rc,cpu] = system('grep -m1 "model name" /proc/cpuinfo');
assert(rc == 0);
cpu = strtrim(cpu);
default_threads = maxNumCompThreads;
template = struct('id','','mode','','threads',0,'replicate',0,...
    'robust_s_hex','','slope_hex','','intercept_hex','','t_hex','',...
    'mad_s_hex','','ols_s_hex','','R22_hex','','s_hex','',...
    'p_hex','');
records = repmat(template,1,144);
idx=0;
for mode=1:2
    if mode==1
        label='DEFAULT';nthreads=maxNumCompThreads;
    else
        maxNumCompThreads(1);
        label='ONE_THREAD';nthreads=maxNumCompThreads;
    end
    for rep=1:3
        for k=1:24
            item=data.samples(k);
            x=double(item.x(:));y=double(item.y(:));
            [beta,st]=robustfit(x,y);
            assert(all(isfinite([beta(:);st.robust_s;st.t(2);st.mad_s])));
            idx=idx+1;
            row=template;row.id=item.id;row.mode=label;
            row.threads=nthreads;row.replicate=rep;
            row.robust_s_hex=num2hex(st.robust_s);
            row.slope_hex=num2hex(beta(2));
            row.intercept_hex=num2hex(beta(1));
            row.t_hex=num2hex(st.t(2));
            row.mad_s_hex=num2hex(st.mad_s);
            row.ols_s_hex=num2hex(st.ols_s);
            row.R22_hex=num2hex(st.R(2,2));
            row.s_hex=num2hex(st.s);
            row.p_hex=num2hex(st.p(2));
            records(idx)=row;
        end
    end
end
maxNumCompThreads(default_threads);
assert(idx==144);
summary = struct('mode',{},'sigma_exact',{},'slope_exact',{},...
 't_exact',{},'R22_exact',{},'mad_s_exact',{},'s_exact',{});
for mode=1:2
    off=(mode-1)*72;
    fields={'robust_s_hex','slope_hex','t_hex','R22_hex','mad_s_hex','s_hex'};
    totals=zeros(1,numel(fields));
    for k=1:24
        a=records(off+k);b=records(off+24+k);c=records(off+48+k);
        assert(strcmp(a.id,b.id) && strcmp(a.id,c.id));
        for j=1:numel(fields)
            f=fields{j};
            totals(j)=totals(j)+strcmp(a.(f),b.(f))*strcmp(a.(f),c.(f));
        end
    end
    summary(end+1)=struct('mode',records(off+1).mode,... %#ok<AGROW>
        'sigma_exact',totals(1),'slope_exact',totals(2),...
        't_exact',totals(3),'R22_exact',totals(4),...
        'mad_s_exact',totals(5),'s_exact',totals(6));
end
report=struct('status','MATHWORKS_R2026B_SOURCE_SELF_REPEATABILITY',...
 'runtime','MathWorks MATLAB','release','2026b',...
 'version',version,'cpu_model',cpu,'architecture',computer('arch'),...
 'processor_count',feature('numcores'),...
 'default_threads',default_threads,...
 'MKL_CBWR',getenv('MKL_CBWR'),'MKL_NUM_THREADS',getenv('MKL_NUM_THREADS'),...
 'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'),...
 'original_function_unmodified',true,'inputs_previously_disclosed',true,...
 'input_sha256',m.input_sha256,'rust_forecast_never_read',true,...
 'sample_count',24,'replicates',3,'modes',{{'DEFAULT','ONE_THREAD'}},...
 'summary',summary,'records',records);
outdir=fullfile(root,'robustfit_repeatability_v1');
if ~exist(outdir,'dir'), mkdir(outdir);end
dest=fullfile(outdir,'genuine_matlab_r2026b_repeatability.json');
fid=fopen(dest,'w');assert(fid>0);
cleaner=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report));
for k=1:numel(summary)
 fprintf('REPEAT_MODE=%s SIGMA=%d SLOPE=%d T=%d QR=%d MAD=%d\n',...
 summary(k).mode,summary(k).sigma_exact,summary(k).slope_exact,...
 summary(k).t_exact,summary(k).R22_exact,summary(k).mad_s_exact);
end
end
