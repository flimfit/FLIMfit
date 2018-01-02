
construct = 'RhoA';

folder = '\\gagri\griw\InvasionAndMetastasis\Sean Warren\Rho Rac Dual Imaging\PiggyBac Cells\2017-12-07 R172 piggy RhoA-GFPRFP and Rac1-CFPVenus 48hrs treatment\Segmented Regions\';

clear data_series;

interface = flim_dll_interface;
donor_data_series = flim_data_series;
donor_data_series.load_data_series([folder construct],'',false,[],'all')

data_series = flim_data_series;
data_series.load_data_series([folder construct],'',false,[],'all')

%%
donor_data_series.load_data_settings([folder construct '_donor_data_settings.xml'])
data_series.load_data_settings([folder 'data_settings.xml'])


donor_fit_params = flim_fitting_params;
donor_fit_params.model = ff_DecayModel();
ff_DecayModel(donor_fit_params.model,'LoadModel',['Q_Qsigma_estimation\' construct '-donor.xml'])
interface.fit(donor_data_series, donor_fit_params);
while interface.fit_in_progress
end

result = interface.fit_result;

E_idx = find(strcmp(result.params,'[1] E_1'));
tauT_idx = find(strcmp(result.params,'[1] tauT_1'));
tauT = []; E = [];
for i=1:result.n_results
    E(i) = result.image_stats{i}.mean(E_idx);
    tauT(i) = result.image_stats{i}.mean(tauT_idx);
end


fit_params = flim_fitting_params;
fit_params.model = ff_DecayModel();
ff_DecayModel(fit_params.model,'LoadModel',['Q_Qsigma_estimation\' construct '-Q-QSigma-model.xml'])
%%
Q = []; Qsigma = [];
for i=1:data_series.n_datasets
    data_series.use = (1:data_series.n_datasets) == i;
    
    groups = ff_DecayModel(fit_params.model,'GetGroups');
    var_idx = strcmp({groups(1).Variables.Name},'tauT_1'); 
    groups(1).Variables(var_idx).InitialValue = tauT(i);
    groups(1).Variables(var_idx).FittingType = 3;
    ff_DecayModel(fit_params.model,'SetGroupVariables',1,groups(1).Variables)
    
    
    interface.fit(data_series, fit_params);
    while interface.fit_in_progress
    end
    result = interface.fit_result;
    Q_idx = find(strcmp(result.params,'[1] Q'));
    Qsigma_idx = find(strcmp(result.params,'[1] I_0'));

    Q(i) = result.image_stats{1}.mean(Q_idx);
    Qsigma(i) = result.image_stats{1}.mean(Qsigma_idx);
end

plot(Qsigma,Q,'x')
[mean(Q) mean(Qsigma)]

