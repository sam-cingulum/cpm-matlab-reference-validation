function run_v1425()
% Independent, source-disclosed binary32 atan and Cauchy tail validation.
assert(exist('OCTAVE_VERSION','builtin') == 0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);
assert(maxNumCompThreads == 1);
for name = ["atan" "acot" "tcdf"]
    assert(startsWith(which(name),matlabroot) || contains(which(name),'built-in'), ...
        '%s is shadowed',name);
end

out = fullfile(fileparts(mfilename('fullpath')),'out');
if ~exist(out,'dir')
    mkdir(out);
end

rng(656517,'twister');
signBit = bitshift(uint32(1),31);
fraction = uint32(randi([0 2^23-1],2048,255));
exponent = bitshift(uint32(0:254),23);
word = reshape(bitor(fraction,repmat(exponent,size(fraction,1),1)),[],1);

% Independently stratify the range where the output departs from identity.
fraction = uint32(randi([0 2^23-1],16384,40));
exponent = bitshift(uint32(113:152),23);
word = [word; reshape(bitor(fraction,repmat(exponent,size(fraction,1),1)),[],1)];
bounds = typecast(single([2^-27 2^-13 2^-12 2^-11 7/16 11/16 19/16 39/16 ...
    2^20 2^21 2^22 2^23 2^24 2^25 2^26 2^27]),'int32');
neighbors = uint32(reshape(bounds + int32((-193:193)'),[],1));
special = uint32(hex2dec(['00000000'; '00000001'; '007fffff'; '00800000'; ...
    '7f7fffff'; '7f800000'; '7f800001'; '7fbfffff'; '7fc00000'; '7fc00001'; '7fffffff']));
signChoice = logical(randi([0 1],size(word)));
word(signChoice) = bitor(word(signChoice),signBit);
angleWords = unique([word; neighbors; bitor(neighbors,signBit); special; bitor(special,signBit)]);
x = typecast(angleWords,'single');

% Cover both Yale t-statistic associations independently of V1422 and V1423.
rWords = unique([uint32(randi([0 hex2dec('3f800000')],65536,1)); ...
    uint32(randi([hex2dec('3e800000') hex2dec('3f800000')],65536,1)); ...
    uint32(hex2dec('3f800000'))-uint32((0:8192)'); uint32(0); uint32(1)]);
r = typecast(sort([rWords; bitor(rWords,signBit)]),'single');
bracket = 1 - r .* r;
tCorr = r .* sqrt(1 ./ bracket);
tPartial = r ./ sqrt(bracket);

for rep = 1:2
    suffix = sprintf('_%d',rep);
    dump(out,['atan' suffix],{'x', x; 'atan_x', atan(x)});
    dump(out,['cauchy' suffix],{'r',r; 't_corr',tCorr; 't_partial',tPartial; ...
        'p_corr',2 .* tcdf(-abs(tCorr),1); 'p_partial',2 .* tcdf(-abs(tPartial),1); ...
        'p_corr_single_df',2 .* tcdf(-abs(tCorr),single(1)); ...
        'p_partial_single_df',2 .* tcdf(-abs(tPartial),single(1))});
end
fprintf('V1425 returned %d atan inputs and %d coefficients for both t associations\n',numel(x),numel(r));
prov = struct('classification','V1425_SOURCE_DISCLOSED_SINGLE_DF1', ...
    'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
    'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'), ...
    'public_commit',getenv('GITHUB_SHA'),'atan',which('atan'),'tcdf',which('tcdf'), ...
    'n_atan',numel(x),'n_r',numel(r));
f = fopen(fullfile(out,'provenance.json'),'w');
assert(f > 0);
fprintf(f,'%s\n',jsonencode(prov));
assert(fclose(f) == 0);
end

function dump(out, name, fields)
b = fopen(fullfile(out,[name '.bin']),'w','ieee-le');
f = fopen(fullfile(out,[name '.csv']),'w');
assert(b > 0 && f > 0);
fprintf(f,'field,class,rows,cols\n');
for k = 1:size(fields,1)
    a = fields{k,2};
    assert(isa(a,'single') && iscolumn(a));
    assert(fwrite(b,typecast(a,'uint32'),'uint32') == numel(a));
    fprintf(f,'%s,%s,%d,%d\n',fields{k,1},class(a),size(a,1),size(a,2));
end
assert(fclose(b) == 0);
assert(fclose(f) == 0);
end
