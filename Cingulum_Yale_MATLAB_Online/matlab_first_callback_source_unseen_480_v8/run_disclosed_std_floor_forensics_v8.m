function run_disclosed_std_floor_forensics_v8()
% RETROSPECTIVE only: V8 original source and its 42 failures were already
% revealed and archived. Never relabel this as the frozen V8 forecast.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
p=fileparts(mfilename('fullpath'));
data=jsondecode(fileread(fullfile(p,'input.json')));
assert(numel(data.cases)==480);
global CINGULUM_STD_V8_CALLBACKS;
rec=struct('id',{},'n',{},'source_std_y_hex',{},'source_var_y_hex',{},...
 'source_mean_y_hex',{},'source_mad_ols_resid_hex',{},...
 'source_scaled_floor_hex',{},'source_original_first_u_hex',{},...
 'reconstructed_first_u_hex',{},'original_equals_reconstructed_first_u_exact',{},...
 'reconstructed_initial_beta_hex',{},'backslash_initial_beta_hex',{},...
 'observed_floor_active',{},'original_final_unmodified',{});
for k=1:480
 c=data.cases(k);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
 x=x(:);y=y(:);n=numel(x);assert(n==double(c.n));
 X=[ones(n,1),x];[Q,R,pivot]=qr(X,'econ','vector');
 betaPivot=R\(Q'*y);beta=zeros(2,1);beta(pivot)=betaPivot;
 CINGULUM_STD_V8_CALLBACKS={};
 [b,st]=robustfit(x,y,@std_v8_bisquare_capture,4.685);
 C=CINGULUM_STD_V8_CALLBACKS;
 assert(numel(C)>=3 && numel(C{1})==n);
 [b_default,st_default]=robustfit(x,y);
 assert(isequal(num2hex(b),num2hex(b_default)));
 assert(isequal(num2hex(st.robust_s),num2hex(st_default.robust_s)));
 radj=(y-X*beta).*(1./sqrt(1-st.h));
 sorted=sort(abs(radj));
 mad=median(sorted(2:end))/0.6745;
 sy=std(y);
 floorScale=1e-6*sy;
 sigma=max(mad,floorScale);
 u=radj./(sigma*4.685);
 exact=isequal(num2hex(u),num2hex(C{1}));
 r=struct();r.id=c.id;r.n=n;r.source_std_y_hex=num2hex(sy);
 r.source_var_y_hex=num2hex(var(y));r.source_mean_y_hex=num2hex(mean(y));
 r.source_mad_ols_resid_hex=num2hex(mad);
 r.source_scaled_floor_hex=num2hex(floorScale);
 r.source_original_first_u_hex=cellstr(num2hex(C{1}(:)));
 r.reconstructed_first_u_hex=cellstr(num2hex(u(:)));
 r.original_equals_reconstructed_first_u_exact=exact;
 r.reconstructed_initial_beta_hex=cellstr(num2hex(beta(:)));
 r.backslash_initial_beta_hex=cellstr(num2hex(X\y));
 r.observed_floor_active=floorScale>mad;
 r.original_final_unmodified=true;
 rec(end+1)=r; %#ok<AGROW>
 CINGULUM_STD_V8_CALLBACKS={};
 if mod(k,80)==0
  fprintf('DISCLOSED_STD_V8_ORIGINAL_MATHWORKS k=%d/480 exact_so_far=%d\n',k,sum([rec.original_equals_reconstructed_first_u_exact]));
 end
end
out=struct('status','DISCLOSED_V8_MATHWORKS_R2026B_STD_FLOOR_RETROSPECTIVE',...
 'source_v8_already_revealed',true,'not_preoracle',true,'release',version('-release'),...
 'matlab_version',version,'mkl_cbwr',getenv('MKL_CBWR'),...
 'case_count',480,'source_std_y_exposed_as_public_MATLAB_builtin',true,...
 'floor_hypothesis','max(adjusted_MAD, 1e-6*std(y))',...
 'exact_first_u_cases',sum([rec.original_equals_reconstructed_first_u_exact]),...
 'active_scale_floor_cases',sum([rec.observed_floor_active]),'records',rec);
f=fopen(fullfile(p,'retrospective_std_floor_v8_matlab_original.json'),'w');assert(f>0);
cleanup=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(out));
end
function w=std_v8_bisquare_capture(u)
global CINGULUM_STD_V8_CALLBACKS;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_STD_V8_CALLBACKS{end+1}=double(u(:));
end
