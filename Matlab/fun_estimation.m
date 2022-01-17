function [obj_smm1,modelTargetsVec,DataTargets,r] = fun_estimation(ParamNames,guess,r0,Parameters,flags,modelTargetsS)
%{
DESCRIPTION:
% This file sets up calibration targets etc. for the calibration and computes 
% the distance b/w model and data.

INPUTS:
- ParamNames: cell array of strings with names of parameters to be calibrated
- guess: vector with calibrated values for internal parameters
- r0: interest rate
- Parameters: structure with model parameters
- flags: structure with flags
- modelTargetsS: structure with some model targets computed in "targets_compute_clean"

OUTPUTS:
obj_smm1: distance between model and targets
model_targets1/modelTargetsVec,DataTargets,r
r
%}

% Data targets - structure
DataTargets.ED = 0;
DataTargets.ave_hours = 1.00;
DataTargets.K_to_Y = 2.65;
DataTargets.exit_ew_p = 15.73;
DataTargets.share_entre_p = 14.7;
DataTargets.share_entre_quint_p = [10.685, 10.747, 12.117, 15, 24.983]';
DataTargets.share_inc_entre_p = 21.04;
DataTargets.assets_e_to_work_p = 39.11;
DataTargets.wealth_med_ratio_E_W = 4.02;
DataTargets.taxes_total_toY_p = 15.2;
DataTargets.share_hiring_se = 20.3;
DataTargets.taxev_quint_inc_p = [2, 5, 6.5, 7.5, 14.2]';
DataTargets.inc_gap_all_p = 11;
%not used for calibration
DataTargets.cond_firm_size_dist = [75.891, 14.700, 5.517, 3.891]';
DataTargets.leverage_mean = 0.289;
DataTargets.gini_incse_p = 43.9;

% Data targets - vector
% IMPORTANT: First target must be ED
DataTargetsVec = [DataTargets.ED;
    DataTargets.ave_hours;
    DataTargets.K_to_Y;
    DataTargets.share_inc_entre_p;
    DataTargets.share_hiring_se;
    DataTargets.exit_ew_p;
    DataTargets.gini_incse_p;
    DataTargets.share_entre_p;
    DataTargets.taxev_quint_inc_p;
    DataTargets.inc_gap_all_p;
    DataTargets.taxes_total_toY_p;
    DataTargets.leverage_mean;
    DataTargets.cond_firm_size_dist];


TargetsNames = {'ED';
    'ave_n_work';
    'K_to_Y';
    'share_inc_entre';
    'share_hiring';
    'exit_ew';
    'gini_incse';
    'share_entre';
    'taxev_quint_inc_1';
    'taxev_quint_inc_2';
    'taxev_quint_inc_3';
    'taxev_quint_inc_4';
    'taxev_quint_inc_5';
    'inc_gap_all';
    'taxes_total_toY';
    'leverage_mean';
    'cond_firm_size_dist_2';
    'cond_firm_size_dist_3';
    'cond_firm_size_dist_4';
    'cond_firm_size_dist_5';};

TargetsNamesShort = {'ED';
    'ave_n_work';
    'K_to_Y';
    'share_inc_entre_true_p';
    'share_hiring_se_p';
    'exit_ew_p';
    'gini_incse_p';
    'share_entre_p';
    'taxev_quint_inc_p';
    'inc_gap_all_p';
    'taxes_total_toY_p';
    'leverage_mean';
    'cond_firm_size_dist'};



%Vector with targets generated by the model
% IMPORTANT: First target must be ED

modelTargetsVec = struct2vec(modelTargetsS,TargetsNamesShort);

% modelTargetsVec = [ED;       % 1
%     ave_n_work;              % 2
%     K_to_Y;                  % 3
%     share_inc_entre_true_p;  % 4
%     share_hiring_se_p;       % 5
%     exit_ew_p;               % 6
%     gini_incse_p;            % 7
%     share_entre_p;           % 8
%     taxev_quint_inc_p;       % 9-13
%     inc_gap_all_p;           % 14
%     taxes_total_toY_p;       % 15
%     leverage_mean;           % 16
%     cond_firm_size_dist];    % 17-20

if length(modelTargetsVec)~=length(DataTargetsVec)
    error('Model and data targets do not match!')
end

num_targets = length(modelTargetsVec);

calibWeightsVec     = ones(num_targets,1);
calibWeightsVec(1)  = 500; %excess demand
calibWeightsVec(3)  = 50; %K/Y
calibWeightsVec(8)  = 10; %share_entre

%options:
% 1 - % Square error divided by absolute value of target
% 2 % abs(error) divided by absolute value of target
% 3 % Square error
% 4 % Absolute error


dist_vec      = (DataTargetsVec-modelTargetsVec).^2;
dist_vec(1)   = abs(DataTargetsVec(1)-modelTargetsVec(1)); %ED
dist_weighted = dist_vec.*calibWeightsVec;
obj_smm1      = sum(dist_weighted);
r = r0;

if flags.do_estimation == 2 && flags.Verbose==1
    fprintf('\n');
    disp('====================================================================')
    fprintf('Current values of the parameters to be calibrated are: \n');
    T = table(ParamNames,guess)
    fprintf('\n');
    T = table(TargetsNames,DataTargetsVec,modelTargetsVec,dist_weighted)
    fprintf('\n');
    fprintf('Current sum of weighted distances is: \n')
    fprintf('obj_smm             %5.3f \n',obj_smm1)
end

if flags.do_estimation == 2
    fid=fopen([flags.results_folder,'\targets_model_estimation.txt'],'at'); % append
    
    %fprintf(fid,'\n');
    fprintf(fid,'Estimated_Parameters ');
    % Estimated Parameters
    fprintf(fid,'%5.6f ', Parameters.beta); % discount factor
    fprintf(fid,'%5.6f ', Parameters.psi); % disutility of work
    fprintf(fid,'%5.6f ', Parameters.delta); % depreciation
    fprintf(fid,'%5.6f ', Parameters.vi); % span of control (production function)
    fprintf(fid,'%5.6f ', Parameters.gamma); % self-empl. labor share
    fprintf(fid,'%5.6f ', Parameters.rho_theta); % persistence of ability shock
    fprintf(fid,'%5.6f ', Parameters.sigmaeps_theta); % stdev of ability shock
    fprintf(fid,'%5.6f ', Parameters.uncmean_theta); % unconditional mean of ability shock
    fprintf(fid,'%5.6f ', Parameters.pn_1); % parameter prob detection: intercept
    fprintf(fid,'%5.6f ', Parameters.pn_2); % parameter prob detection: slope
    fprintf(fid,'%5.6f ', Parameters.cc0); % parameter prob detection: intercept
    fprintf(fid,'%5.6f ', Parameters.ksi_tax); % scale param for GS tax function
    fprintf(fid,'%5.6f ', Parameters.lambda); % collateral constraint
    fprintf(fid,'Targets ');
    % % % Listing Targets (REVISION)
    fprintf(fid,'%5.4f ', modelTargetsVec'); %write in a row
    fprintf(fid,'OBJSMM ');
    fprintf(fid,'%5.4f ',obj_smm1);
    fprintf(fid,'\n');
    %fprintf(fid,'=============================================================');
    fclose(fid);
end %end flag do estimation

end %END function




