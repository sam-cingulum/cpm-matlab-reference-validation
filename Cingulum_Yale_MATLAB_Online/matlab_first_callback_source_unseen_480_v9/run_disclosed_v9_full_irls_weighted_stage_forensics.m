function run_disclosed_v9_full_irls_weighted_stage_forensics()
% RETROSPECTIVE ONLY. V9 original first-callback input/source was already
% disclosed in three runs (43342252905/43342287513/43342291721).
% This script is NEVER a new source-unseen test and must NOT be labelled one.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(strcmp(version('-release'),'2026b'));
maxNumCompThreads(1);
p=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(p,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_MATHWORKS_R2026B_RAW_XY_FIRST_BISQUARE_CALLBACK_480_V9'));
assert(numel(raw.cases)==480);
global CINGULUM_V9_WLS_REVEALED_CAPTURE;
records=struct('id',{},'n',{},'scenario',{},'pivot_w',{},'qw_hex',{},'rw_hex',{},'qwy_hex',{},...
  'qu_hex',{},'ru_hex',{},'quwy_hex',{},...
  'unpivoted_qr_beta_hex',{},'pivoted_qr_beta_hex',{},'lscov_beta_hex',{},...
  'w_first_hex',{},'wx_first_hex',{},'wy_first_hex',{},...
  'next_wls_beta_backslash_hex',{},'source_second_u_hex',{},'source_second_w_hex',{},...
  'second_u_from_wls_hex',{},'second_u_wls_exact_elements',{},...
  'source_callback_count',{},'source_final_beta_hex',{},'source_final_robust_s_hex',{},...
  'source_final_mad_hex',{},'source_final_s_hex',{},'source_final_w_hex',{},...
  'original_and_callback_noninterfering',{});
for k=1:480
 c=raw.cases(k);x=hex2num(char(c.x_hex));y=hex2num(char(c.y_hex));
 x=x(:);y=y(:);n=numel(x);X=[ones(n,1),x];
 [b,st]=robustfit(x,y);
 CINGULUM_V9_WLS_REVEALED_CAPTURE={};
 [bcb,stcb]=robustfit(x,y,@capture_v9_revealed_irls,4.685);
 cc=CINGULUM_V9_WLS_REVEALED_CAPTURE;
 assert(numel(cc)>=3 && numel(cc)<100);
 assert(isequal(num2hex(b),num2hex(bcb)));
 for field={'robust_s','mad_s','s','w','h'}
   name=field{1};
   assert(isequal(num2hex(st.(name)),num2hex(stcb.(name))));
 end
 w=cc{1}.w(:);
 WX=X.*sqrt(w);Wy=y.*sqrt(w);
 [Qw,Rw,pw]=qr(WX,'econ','vector');
 assert(isequal(sort(pw),[1 2]));
 bw=WX\Wy;
 [Qu,Ru]=qr(WX,'econ');
 quwy=Qu'*Wy;
 bu=Ru\quwy;
 bp=zeros(2,1);bp(pw)=Rw\(Qw'*Wy);
 bl=lscov(X,y,w);
 uw=independent_next_u_v9_revealed(x,y,st.h,bw);
 qwy=Qw'*Wy;
 rec=struct();
 rec.id=c.id;rec.n=n;rec.scenario=c.scenario;rec.pivot_w=pw;
 rec.qw_hex=cellstr(num2hex(Qw(:)));
 rec.rw_hex=cellstr(num2hex(Rw(:)));
 rec.qwy_hex=cellstr(num2hex(qwy(:)));
 rec.qu_hex=cellstr(num2hex(Qu(:)));
 rec.ru_hex=cellstr(num2hex(Ru(:)));
 rec.quwy_hex=cellstr(num2hex(quwy(:)));
 rec.unpivoted_qr_beta_hex=cellstr(num2hex(bu(:)));
 rec.pivoted_qr_beta_hex=cellstr(num2hex(bp(:)));
 rec.lscov_beta_hex=cellstr(num2hex(bl(:)));
 rec.w_first_hex=cellstr(num2hex(w(:)));
 rec.wx_first_hex=cellstr(num2hex(WX(:)));
 rec.wy_first_hex=cellstr(num2hex(Wy(:)));
 rec.next_wls_beta_backslash_hex=cellstr(num2hex(bw(:)));
 rec.source_second_u_hex=cellstr(num2hex(cc{2}.u(:)));
 rec.source_second_w_hex=cellstr(num2hex(cc{2}.w(:)));
 rec.second_u_from_wls_hex=cellstr(num2hex(uw(:)));
 rec.second_u_wls_exact_elements=sum(strcmp(rec.second_u_from_wls_hex,rec.source_second_u_hex));
 rec.source_callback_count=numel(cc);
 rec.source_final_beta_hex=cellstr(num2hex(b(:)));
 rec.source_final_robust_s_hex=num2hex(st.robust_s);
 rec.source_final_mad_hex=num2hex(st.mad_s);
 rec.source_final_s_hex=num2hex(st.s);
 rec.source_final_w_hex=cellstr(num2hex(st.w(:)));
 rec.original_and_callback_noninterfering=true;
 records(end+1)=rec; %#ok<AGROW>
 CINGULUM_V9_WLS_REVEALED_CAPTURE={};
 if mod(k,80)==0
  fprintf('DISCLOSED_V9_WLS_ORIGINAL_MATLAB %d/480 SECOND_U=%d\n',k,sum([records.second_u_wls_exact_elements]));
 end
end
report=struct('status','RETROSPECTIVE_ALREADY_DISCLOSED_V9_ORIGINAL_MATLAB_WEIGHTED_QR_AND_SECOND_CALLBACK',...
 'release',version('-release'),'matlab_version',version,'case_count',480,...
 'source_unseen',false,'original_unmodified',true,'callback_noninterference_asserted',true,...
 'input_sha256','d85eb82d20f1293436c8d510026f63bb89f79be28346f67b839df11f46c7093d',...
 'second_u_wls_exact_elements_total',sum([records.second_u_wls_exact_elements]),...
 'second_u_total',sum([records.n]),'records',records);
output=getenv('WLS_V9_REVEALED_OUTPUT');assert(~isempty(output));
f=fopen(fullfile(p,output),'w');assert(f>0);clean=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(report));
end
function w=capture_v9_revealed_irls(u)
global CINGULUM_V9_WLS_REVEALED_CAPTURE;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_V9_WLS_REVEALED_CAPTURE{end+1}=struct('u',double(u(:)),'w',double(w(:)));
end
function u=independent_next_u_v9_revealed(x,y,h,b)
r=y-([ones(numel(x),1),x]*b);
adjusted=r.*(1./sqrt(1-h));
s=sort(abs(adjusted));
mad=median(s(2:end))/0.6745;
scale=max(mad,1e-6*std(y));
u=adjusted./(scale*4.685);
end
