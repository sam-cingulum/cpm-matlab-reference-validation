function run_ohbm_robustfit_delegate_metadata()
% Licensed R2026b metadata-only exploration; no proprietary source export.
assert(~exist('OCTAVE_VERSION','builtin'));
assert(strcmp(version('-release'),'2026b'));
wrapper=which('robustfit');
helper=fullfile(fileparts(wrapper),'private','statrobustfit.m');
assert(exist(helper,'file')==2,'Original robustfit delegated helper missing');
raw=fileread(helper);
lines=regexp(raw,'\r\n|\n','split');
fprintf('SOURCE_HELPER_LINE_COUNT=%d\n',numel(lines));
fprintf('SOURCE_HELPER_BYTES=%d\n',numel(raw));
functional={'robust_s','robustsigma','robustsig','sigma','slope','covb','psip','wfun','statrobustfit','madsigma'};
for fi=1:numel(functional)
 term=functional{fi};
 hit=find(contains(lower(string(lines)),term));
 fprintf('TOKEN=%s COUNT_LINES=%d INDEX=',term,numel(hit));
 fprintf('%d,',hit);fprintf('\n');
end
% Identify only the helper's algorithmic function-call identifier names,
% not its expressions, comments, line text or proprietary implementation.
matches={};
for i=1:numel(lines)
 t=regexp(lines{i},'(?<![\w\.])([A-Za-z]\w*)\s*\(','tokens');
 for k=1:numel(t)
  if ~isempty(t{k}),matches{end+1}=t{k}{1};end %#ok<AGROW>
 end
end
[freq,names]=groupcounts(string(matches(:)));
[~,ix]=sort(freq,'descend');
for i=1:min(numel(ix),60)
 fprintf('CALL_METADATA %s COUNT=%d\n',names(ix(i)),freq(ix(i)));
end
% Narrow just the specific scale-output symbols, keeping only identifiers.
for i=1:numel(lines)
 ln=lines{i};
 if contains(lower(ln),'robust_s') || contains(lower(ln),'robustsigma')
  ids=unique(regexp(ln,'[A-Za-z]\w*','match'));
  fprintf('SCALE_METADATA_LINE=%d IDS=%s\n',i,strjoin(ids,','));
 end
end
private_dir=fullfile(fileparts(wrapper),'private');
d=dir(fullfile(private_dir,'*robust*.m'));
for i=1:numel(d)
 fprintf('NEARBY_ROBUST_HELPER_NAME=%s SIZE=%d\n',d(i).name,d(i).bytes);
end
clear raw lines;
fprintf('NO_MATHWORKS_PROPRIETARY_SOURCE_BODY_EXPORTED\n');
end
