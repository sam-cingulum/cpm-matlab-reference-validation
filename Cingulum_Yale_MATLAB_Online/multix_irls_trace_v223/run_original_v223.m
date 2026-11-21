function run_original_v223()
% V223 SOURCE-DISCLOSED genuine R2026b original robustfit callback/weighted
% QR diagnostic, based on already-disclosed V211 raw X/y. No first-blind claim.
assert(exist('OCTAVE_VERSION','builtin')==0);
assert(contains(version,'(R2026b) Update 1'));
assert(strcmp(getenv('MKL_CBWR'),'COMPATIBLE'));
maxNumCompThreads(1);assert(maxNumCompThreads==1);
root=fileparts(mfilename('fullpath'));
raw=jsondecode(fileread(fullfile(root,'input.json')));
assert(strcmp(raw.schema,'CINGULUM_V211_R2026B_RAW_MULTIPREDICTOR_ROBUSTFIT_FIRST_BLIND'));
assert(raw.seed==202611220211 && numel(raw.cases)==48);
global CINGULUM_MULTIX_V223_CALLBACKS;
rows=struct('id',{},'n',{},'p',{},'rep',{},'callback_count',{},...
 'original_b_hex',{},'custom_b_hex',{},'b_original_exact',{},...
 'stats_all_17_exact',{},'stats_exact_fields',{},'first_callback_u_hex',{},...
 'first_callback_w_hex',{},'callbacks',{},...
 'original_h_hex',{},'original_R_hex',{},'original_Qy_hex',{});
fields={'ols_s';'robust_s';'mad_s';'s';'resid';'rstud';'se';'covb'; ...
 'coeffcorr';'t';'p';'w';'Qy';'R';'dfe';'h';'Rtol'};
for rep=1:2
 for i=1:48
  c=raw.cases(i);n=double(c.n);p=double(c.p);
  assert(ismember(n,[33 49 73]) && ismember(p,[2 3 4 5]));
  X=reshape(hex2num(char(c.x_colmajor_hex)),n,p);
  y=hex2num(char(c.y_hex));y=y(:);
  A=[ones(n,1),X];
  [original_b,original_stats]=robustfit(X,y);
  assert(isequal(fieldnames(original_stats),fields));
  CINGULUM_MULTIX_V223_CALLBACKS={};
  [custom_b,custom_stats]=robustfit(X,y,@record_bisquare,4.685);
  calls=CINGULUM_MULTIX_V223_CALLBACKS;
  assert(numel(calls)>=2 && numel(calls)<=60);
  stage=struct('ordinal',{},'u_hex',{},'w_hex',{},...
   'backslash_b_hex',{},'Q_hex',{},'R_hex',{},'pivot_hex',{},'Qy_pivot_hex',{});
  for j=1:numel(calls)
   w=hex2num(char(calls{j}.w_hex));w=w(:);
   assert(numel(w)==n && all(w>=0) && all(isfinite(w)));
   root_w=sqrt(w);
   wx=A.*root_w;wy=y.*root_w;
   b=wx\wy;
   if j<=2 || j>=numel(calls)-2
    [Q,R,piv]=qr(wx,'econ','vector');
    qy=Q'*wy;
    entry=struct('ordinal',j,'u_hex',{calls{j}.u_hex},...
     'w_hex',{calls{j}.w_hex},'backslash_b_hex',{bits(b)},...
     'Q_hex',{bits(Q)},'R_hex',{bits(R)},...
     'pivot_hex',{bits(piv)},'Qy_pivot_hex',{bits(qy)});
   else
    entry=struct('ordinal',j,'u_hex',{calls{j}.u_hex},...
     'w_hex',{calls{j}.w_hex},'backslash_b_hex',{bits(b)},...
     'Q_hex',{{}},'R_hex',{{}},'pivot_hex',{{}},'Qy_pivot_hex',{{}});
   end
   stage(end+1)=entry; %#ok<AGROW>
  end
  equal=struct;
  for j=1:numel(fields)
   key=fields{j};
   equal.(key)=isequal(num2hex(original_stats.(key)),num2hex(custom_stats.(key)));
  end
  row=struct('id',c.id,'n',n,'p',p,'rep',rep,...
   'callback_count',numel(calls),...
   'original_b_hex',{bits(original_b)},...
   'custom_b_hex',{bits(custom_b)},...
   'b_original_exact',isequal(num2hex(original_b),num2hex(custom_b)),...
   'stats_all_17_exact',all(cellfun(@(v) isequal(v,true),struct2cell(equal))),...
   'stats_exact_fields',equal,...
   'first_callback_u_hex',{calls{1}.u_hex},...
   'first_callback_w_hex',{calls{1}.w_hex},...
   'callbacks',{stage},'original_h_hex',{bits(original_stats.h)},...
   'original_R_hex',{bits(original_stats.R)},...
   'original_Qy_hex',{bits(original_stats.Qy)});
  rows(end+1)=row; %#ok<AGROW>
 end
end
for i=1:48
 a=rows(i);b=rows(i+48);
 a=rmfield(a,'rep');b=rmfield(b,'rep');
 assert(isequal(a,b),'original MATLAB callback trace repeats differ');
end
out=struct('classification','V223_SOURCE_DISCLOSED_ORIGINAL_MULTIX_CALLBACK_WEIGHTED_QR_TRACE',...
 'source_disclosed',true,'new_first_blind_certificate',false,...
 'release',version,'computer',computer,'mkl_cbwr',getenv('MKL_CBWR'),...
 'original_robustfit_unchanged',true,...
 'custom_callback_is_independently_written',true,...
 'source_input_sha256','5836d8f460b64c889feda69ee69dc4792a5ff85bf120600f346171150eb2a559',...
 'run',getenv('GITHUB_RUN_ID'),'repetitions',2,'cases',48,'rows',rows);
fid=fopen(fullfile(root,'original.json'),'w');assert(fid>0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(out));
end
function w=record_bisquare(u)
global CINGULUM_MULTIX_V223_CALLBACKS;
w=double(abs(u)<1).*(1-u.^2).^2;
CINGULUM_MULTIX_V223_CALLBACKS{end+1}=struct(...
 'u_hex',{bits(u)},'w_hex',{bits(w)});
end
function b=bits(v)
b=cellstr(num2hex(double(v(:))));
end
