function original_matlab_v10_beta_gamma_for_abi_v8
% Genuine R2026b interpreter; source-disclosed frozen V10 inputs only.
% Data remains ephemeral inside the authenticated GitHub runner.
assert(strcmp(version('-release'),'2026b'),'Genuine R2026b required');
here=fileparts(mfilename('fullpath'));
inp=fullfile(here,'..','matlab_beta_mean_switch_v10_disclosed','input.json');
D=jsondecode(fileread(inp));
assert(D.gamma_count==60 && D.beta_count==2812);
assert(strcmp(D.source_unseen_V12,'NOT_GENERATED'));
fid=fopen(fullfile(here,'original_v10_gamma_beta_hex_v8.txt'),'w');
assert(fid>0);
for i=1:D.gamma_count
   h=char(D.gamma(i).x_hex);
   x=hex2num(h);
   fprintf(fid,'G %s %s\n',h,num2hex(gammaln(x)));
end
for i=1:D.beta_count
   xh=char(D.beta(i).x_hex); ah=char(D.beta(i).a_hex); bh=char(D.beta(i).b_hex);
   x=hex2num(xh);a=hex2num(ah);b=hex2num(bh);
   lower=betainc(x,a,b,'lower');upper=betainc(x,a,b,'upper');
   fprintf(fid,'B %s %s %s %s %s\n',xh,ah,bh,num2hex(lower),num2hex(upper));
end
fclose(fid);
fprintf('ORIGINAL_MATLAB_R2026B_V10_GAMMA_60_AND_BETA_2812_EVALUATED\n');
end
