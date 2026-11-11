function run_ohbm_robust_sigma_helper_metadata()
% Licensed MathWorks R2026b helper algorithm fingerprint, no source export.
% Source facts are function identifiers / numeric metadata, not source code.
assert(~exist('OCTAVE_VERSION','builtin'));
assert(strcmp(version('-release'),'2026b'));
wrapper=which('robustfit');assert(~isempty(wrapper));
helper=fullfile(fileparts(wrapper),'private','statrobustsigma.m');
assert(exist(helper,'file')==2);
raw=fileread(helper);
lines=regexp(raw,'\r\n|\n','split');
fprintf('INTERNAL_ROBUST_SIGMA_HELPER_NAME=statrobustsigma\n');
fprintf('INTERNAL_ROBUST_SIGMA_HELPER_LINES=%d BYTES=%d\n',numel(lines),numel(raw));
terms={'eps','sqrt(eps','diff','psi','wfun','tune','mean','sum','sigma',...
 'lambda','sq','h','robust_s','sqrt','feval','deriv','step','wfun','robust'};
low=lower(raw);
for i=1:numel(terms)
 key=terms{i};
 fprintf('SEMANTIC_TOKEN=%s COUNT=%d\n',key,numel(strfind(low,key)));
end
func_names={};
for i=1:numel(lines)
 line=lines{i};
 if startsWith(strtrim(line),'function ')
  fnames=regexp(line,'[A-Za-z]\w*\s*\(','match');
  fprintf('HELPER_FUNCTION_LINE=%d SIGNATURE_TOKEN_COUNT=%d\n',i,numel(fnames));
  inputs=regexp(line,'statrobustsigma\s*\(([^)]*)\)','tokens','once');
  if ~isempty(inputs)
   params=strtrim(strsplit(inputs{1},','));
   assert(all(cellfun(@(p)~isempty(regexp(p,'^[a-zA-Z]\w*$','once')),params)));
   fprintf('HELPER_PARAMETER_NAMES_IN_DECLARED_ORDER=%s\n',strjoin(params,','));
  end
 end
 if startsWith(strtrim(line),'%'),continue;end
 if isempty(strtrim(line)),continue;end
 ids=unique(regexp(line,'[A-Za-z]\w*','match'));
 ops=[sum(line=='*'),sum(line=='/'),sum(line=='+'),sum(line=='-'),...
      sum(line=='^'),sum(line=='.'),sum(line=='='),...
      sum(line=='('),sum(line==')')];
 if contains(lower(line),'psi') || contains(lower(line),'sigma') ||...
    contains(lower(line),'eps') || contains(lower(line),'lambda') ||...
    contains(lower(line),'wfun') || contains(lower(line),'feval') ||...
    contains(lower(line),'mean') || contains(lower(line),'sum') ||...
    contains(lower(line),'max')
  fprintf('MATH_HELPER_LINE_META=%d IDS=%s OPERATORS=%d,%d,%d,%d,%d,%d,%d,%d,%d\n',...
      i,strjoin(ids,','),ops);
 end
end
% Line-local numeric and variable fingerprints only. Do not export source.
% This isolates the finite-difference perturbation and correction pathway.
for i=25:min(62,numel(lines))
 line=lines{i};
 if isempty(strtrim(line)) || startsWith(strtrim(line),'%'),continue;end
 words=unique(regexp(line,'[A-Za-z]\w*','match'));
 literals=regexp(line,'(?<![A-Za-z0-9_])(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+\-]?\d+)?','match');
 op=[sum(line=='*'),sum(line=='/'),sum(line=='+'),sum(line=='-'),...
    sum(line=='^'),sum(line=='.'),sum(line=='='),sum(line=='('),sum(line==')')];
 fprintf('FINITE_DIFFERENCE_SOURCE_META_LINE=%d IDENTIFIERS=%s NUMERIC_LITERALS=%s OPS=%d,%d,%d,%d,%d,%d,%d,%d,%d\n',...
    i,strjoin(words,','),strjoin(literals,','),op);
end
% Return only existence/line counts for helpers it mentions, not source.
folder=fileparts(helper);
d=dir(fullfile(folder,'statrobust*.m'));
for i=1:numel(d)
 fprintf('HELPER_DISCOVERY=%s BYTES=%d\n',d(i).name,d(i).bytes);
end
clear raw lines;
fprintf('NO_PROPRIETARY_MATHWORKS_FUNCTION_CODE_EXPORTED\n');
end
