function run_all
% Execute all six independently pinned synthetic Yale scenarios in MATLAB.
% Preserve output for every scenario even if numerical parity fails.
cases={'baseline','clean','severe_outlier','rescaled','reversed','47_subjects'};
failures={};
for i=1:numel(cases)
    scenario=cases{i};
    fprintf('\n===== ORIGINAL YALE SOURCE IN MATHWORKS MATLAB: %s =====\n',scenario);
    try
        run_one(scenario);
    catch ME
        failures{end+1}=sprintf('%s: %s',scenario,ME.message); %#ok<AGROW>
        fprintf(2,'TEST SCENARIO FAILED: %s: %s\n',scenario,ME.message);
        % Keep going: complete evidence even when methods fail.
    end
end
if ~isempty(failures)
    fprintf(2,'\nGenuine MATLAB scientific parity failures (%d scenarios):\n',numel(failures));
    for j=1:numel(failures)
        fprintf(2,'  %s\n',failures{j});
    end
    error('MATLAB_PARITY_BATTERY_FAILED: All completed original-source artefacts retained.');
end
fprintf('\nMATLAB_PARITY_ALL_SIX_SCENARIOS_PASS\n');
end
