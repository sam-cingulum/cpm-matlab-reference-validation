function out=cpm_independent_bisquare_fit_raw_v1(x,y)
% Independently developed numerical model of one-predictor robust regression.
% Uses only raw x/y and publicly documented MATLAB operations. Absolutely
% NO call to original MathWorks robustfit or nonpublic toolbox helpers.
%
% This is a research hypothesis, not certified raw-Rust binary64 parity.
x=double(x(:));y=double(y(:));n=numel(x);p=2;tune=4.685;
assert(numel(y)==n && n>=10 && all(isfinite([x;y])));
X=[ones(n,1),x];
[Q,Rpivot,pivot]=qr(X,'econ','vector');
assert(isequal(sort(double(pivot(:))'),1:2));
R=Rpivot;
if isequal(double(pivot(:)'),[2 1])
 R=Rpivot([2 1],[2 1]);
end
Z=X/R;
h=sum(Z.^2,2);
assert(all(isfinite(h)) && all(h>=0) && all(h<1));
u2=Rpivot\(Q'*y);
b=zeros(p,1);b(pivot)=u2;
b0=b;
r0=y-X*b;
base_ols_s=sqrt(sum(r0.^2)/(n-p));
niter=0;limit=sqrt(eps);
while true
 r=y-X*b;
 radj=r.*(1./sqrt(1-h));
 sorted=sort(abs(radj));
 mad=median(sorted(2:end))/0.6745;
 assert(isfinite(mad) && mad>0);
 u=radj./(mad*tune);
 w=double(abs(u)<1).*(1-u.^2).^2;
 Xw=X.*sqrt(w);
 yw=y.*sqrt(w);
 bnext=Xw\yw;
 niter=niter+1;
 assert(niter<500,'IRLS iteration convergence guard exceeded');
 rel=max(abs(bnext-b)./max(abs(bnext),eps));
 finished=rel<limit;
 b=bnext;
 if finished,break;end
end
% Original converged beta is determined by the most recent weighted update.
% A further postfit weight callback precedes the two finite differences.
residual=y-X*b;
radj=residual.*(1./sqrt(1-h));
sorted=sort(abs(radj));
mad=median(sorted(2:end))/0.6745;
scale=mad*tune;
u=radj./scale;
weightfun=@(v) double(abs(v)<1).*(1-v.^2).^2;
phi=u.*weightfun(u);
delta=0.0001;
u_lower=u-delta;phi_lower=u_lower.*weightfun(u_lower);
u_upper=u+delta;phi_upper=u_upper.*weightfun(u_upper);
dphi=(phi_upper-phi_lower)./(2*delta);
m1=mean(dphi);
m2=sum((1-h).*(phi.^2))/(n-p);
K=1+(p/n)*(1-m1)/m1;
rs=K*sqrt(m2)*scale/m1;
assert(all(isfinite([rs;m1;m2;K])) && rs>0);
out=struct;
out.beta=b;out.initial_beta=b0;out.ols_s=base_ols_s;
out.robust_s=rs;out.mad_s=mad;out.R=R;out.h=h;out.w=w;
out.initial_ols_residual=r0;out.residual=residual;out.postfit_u=u;
out.iterations=niter;
out.inferred_callback_count=niter+3;
out.m1=m1;out.m2=m2;out.K=K;
out.stopping_rule='max(abs(beta_next-beta)./max(abs(beta_next),eps)) < sqrt(eps)';
end
