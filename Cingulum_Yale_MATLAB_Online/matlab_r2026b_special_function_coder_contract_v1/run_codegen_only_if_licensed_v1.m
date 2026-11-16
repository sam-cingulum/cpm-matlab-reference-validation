function run_codegen_only_if_licensed_v1(outputDir)
% Explicitly licensed MATLAB Coder experiment. No licence workaround.
% Generated vendor C/C++ MUST NOT be distributed from this public repository.
% If unavailable, fail closed before calling codegen.
assert(strcmp(version('-release'),'2026b'),'Require genuine R2026b');
assert(exist('codegen','file')==2 || exist('codegen','file')==7, ...
    'MATLAB_CODER_NOT_INSTALLED');
assert(license('test','MATLAB_Coder')==1, 'MATLAB_CODER_LICENSE_NOT_AVAILABLE');
assert(nargin==1 && ischar(outputDir), 'PRIVATE_OUTPUT_DIRECTORY_REQUIRED');
assert(~isempty(outputDir),'PRIVATE_OUTPUT_DIRECTORY_REQUIRED');
assert(~contains(outputDir,'Cingulum_Yale_MATLAB_Online'),...
    'DO_NOT_STORE_GENERATED_VENDOR_SOURCE_IN_PUBLIC_REPO');
cfg = coder.config('lib');
cfg.TargetLang = 'C';
cfg.GenCodeOnly = true;
cfg.GenerateReport = false;
codegen('matlab_original_kernel_codegen_entry_v1', '-config', cfg, ...
    '-args', {double(0.25),double(2.5),double(3.5)}, '-d', outputDir);
fprintf('LICENSED_CODER_GENERATION_COMPLETED_BUT_NUMERICAL_IDENTITY_UNCERTIFIED\n');
end
