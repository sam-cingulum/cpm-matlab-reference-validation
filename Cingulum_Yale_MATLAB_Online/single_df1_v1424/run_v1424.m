function run_v1424()
% V1424 source-disclosed diagnostic for the single-precision Cauchy tail.
% The input words are derived from the published, synthetic V1422 and V1423 cases.
% The independent atan sweep uses seeded binary32 words and branch boundaries.
assert(exist('OCTAVE_VERSION','builtin') == 0);
assert(contains(version,'(R2026b) Update 1'));
maxNumCompThreads(1);
assert(maxNumCompThreads == 1);
for name = ["atan" "acot" "tcdf" "abs"]
    assert(startsWith(which(name),matlabroot) || contains(which(name),'built-in'), ...
        '%s is shadowed',name);
end

root = fileparts(mfilename('fullpath'));
out = fullfile(root,'out');
if ~exist(out,'dir')
    mkdir(out);
end
f = fopen(fullfile(root,'t_words.csv'),'r');
assert(f > 0);
assert(strcmp(fgetl(f),'t_abs_u32_hex,scalar_check'));
inputs = textscan(f,'%s%u8','Delimiter',',');
fclose(f);
samples = uint32(hex2dec(inputs{1}));
assert(issorted(samples) && numel(unique(samples)) == numel(samples));
assert(all(inputs{2} <= 1));

special = uint32([0; 1; hex2dec('007fffff'); hex2dec('00800000'); ...
    hex2dec('3f800000'); hex2dec('7f7fffff'); hex2dec('7f800000'); ...
    hex2dec('7fc00001'); hex2dec('ffc00001')]);
tWords = unique([samples; special; bitor(samples(1:127:end),uint32(2^31)); ...
    bitor(special,uint32(2^31))]);
t = typecast(tWords,'single');
scalarWords = unique([samples(logical(inputs{2})); special; bitor(special,uint32(2^31))]);
scalarT = typecast(scalarWords,'single');
assert(all(ismember(scalarWords,tWords)));

rng(1424,'twister');
bounds = typecast(single([2^-27 2^-12 0.4375 0.5 0.6875 1 1.1875 1.5 2.4375 2^25 2^26]),'int32');
near = uint32(reshape(bounds + int32((-64:64)'),[],1));
raw = uint32(randi([0 hex2dec('7f800000')],32768,1));
dense = uint32(randi([hex2dec('3b000000') hex2dec('41800000')],131072,1));
positive = unique([special; near; raw; dense; tWords]);
xWords = unique([positive; bitor(near,uint32(2^31)); ...
    bitor(positive(1:7:end),uint32(2^31))]);
x = typecast(xWords,'single');

for rep = 1:2
    suffix = sprintf('_%d',rep);
    dump(out, ['tails' suffix], tails(t));
    first = tails(scalarT(1));
    result = cell(size(first,1),2);
    result(:,1) = first(:,1);
    for k = 1:size(first,1)
        result{k,2} = repmat(first{k,2},numel(scalarT),1);
    end
    for i = 2:numel(scalarT)
        row = tails(scalarT(i));
        for k = 1:size(result,1)
            assert(strcmp(class(result{k,2}),class(row{k,2})));
            result{k,2}(i) = row{k,2};
        end
    end
    dump(out, ['tails_scalar' suffix], result);
    dump(out, ['atan_sweep' suffix], {'x', x; 'atan_x', atan(x)});
end

fprintf('V1424 returned %d tail inputs, %d scalar checks, %d atan sweep inputs\n', ...
    numel(t),numel(scalarT),numel(x));
prov = struct('classification','V1424_SOURCE_DISCLOSED_SINGLE_DF1', ...
    'V12','SEALED','release',version,'blas',version('-blas'),'lapack',version('-lapack'), ...
    'mkl_cbwr',getenv('MKL_CBWR'),'run_id',getenv('GITHUB_RUN_ID'), ...
    'public_commit',getenv('GITHUB_SHA'),'atan',which('atan'),'acot',which('acot'), ...
    'tcdf',which('tcdf'),'n_t',numel(t),'n_scalar',numel(scalarT),'n_sweep',numel(x));
f = fopen(fullfile(out,'provenance.json'),'w');
assert(f > 0);
fprintf(f,'%s\n',jsonencode(prov));
fclose(f);
end

function result = tails(t)
a = abs(t);
u = 1 ./ a;
angle = atan(u);
c = acot(a);
lower = tcdf(-a,1);
upper = tcdf(a,1,'upper');
result = {
    't', t;
    'absolute_t', a;
    'reciprocal', u;
    'atan_t', atan(t);
    'atan_reciprocal', angle;
    'acot_t', acot(t);
    'acot_absolute_t', c;
    'atan_over_pi', angle ./ pi;
    'acot_over_pi', c ./ pi;
    'tcdf_lower_negative', lower;
    'tcdf_upper_positive', upper;
    'tcdf_lower_single_df', tcdf(-a,single(1));
    'tcdf_upper_single_df', tcdf(a,single(1),'upper');
    'two_sided', 2 .* lower;
    };
end

function dump(out, name, fields)
b = fopen(fullfile(out,[name '.bin']),'w','ieee-le');
f = fopen(fullfile(out,[name '.csv']),'w');
assert(b > 0 && f > 0);
fprintf(f,'field,class,rows,cols\n');
for k = 1:size(fields,1)
    a = fields{k,2};
    if isa(a,'single')
        words = typecast(a(:),'uint32');
        kind = 'uint32';
    else
        assert(isa(a,'double'));
        words = typecast(a(:),'uint64');
        kind = 'uint64';
    end
    assert(fwrite(b,words,kind) == numel(a));
    fprintf(f,'%s,%s,%d,%d\n',fields{k,1},class(a),size(a,1),size(a,2));
end
assert(fclose(b) == 0);
assert(fclose(f) == 0);
end
