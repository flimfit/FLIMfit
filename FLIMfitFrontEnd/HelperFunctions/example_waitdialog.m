% Sample code for ProgressDialog.

% Copyright 2008-2009 Levente Hunyadi
function example_waitdialog

pause(0.1);

% show progress bar dialog
dlg = ProgressDialog();

maxiter = 50;
for iter = 1 : maxiter
    % do any long-running operation
    pause(0.1);
    
    % update progress bar
    dlg.FractionComplete = iter/maxiter;
    
    % update status message
    dlg.StatusMessage = sprintf('%d%% complete', fix(100*iter/maxiter));
end

% destroy progress bar dialog explicitly
delete(dlg);

% create progress bar dialog with custom status message
dlg = ProgressDialog( ...
    'StatusMessage', 'Please wait until operation terminates...', ...
    'FractionComplete', 0.25);
pause(2);

% hide status message
dlg.StatusMessage = [];
dlg.FractionComplete = 1;
pause(2);
% dialog is automatically destroyed when variable dlg is assigned to

switch dlg.Implementation
    case 'java'
        % create progress bar with indeterminate state
        % supported by Java implementation only
        dlg = ProgressDialog( ...
            'StatusMessage', 'Close the dialog to continue', ...
            'Indeterminate', true);
        uiwait(dlg);
end

% demonstrate procedural syntax
dlg = waitdialog(0.0);
pause(1);
waitdialog(dlg, 0.25);
pause(1);
waitdialog(dlg, 0.5, 'Committing...');
pause(1);
waitdialog(dlg, 0.75);
pause(1);
waitdialog(dlg, 'Finalizing...', 1.0);
pause(1);
delete(dlg);
