function Setup_MMIC_operation(MMIC, config, flag)
% Function to setup MMIC for going to operation state.
% This function configures the DMUX, clears results, configures ramp
% scenario, configures RF frequency, configures TX power, configures RX,
% Executes RX calibration and gets the temperature of the device
%
% Parameters:
%   MMIC : MMIC object for the MMIC    
%   config: configuration parameter struct

    h              = strata.CtrxHelperFunctions();

    % Configure digital IO via COnfigure_DMUX() 
    MMIC.CTRX_FW_Cmd.runConfigure_DMUX();

    % 上电必须写入一次数据，掉电丢失数据
    if flag == true
        if isfield (config, 'sequencerFile')
            % Download Sequencer Program 
            result = MMIC.radarCtrx.loadSequencerData(config.sequencerFile);            % written words:47
            
            % Configure Ramp scenario  
            MMIC.CTRX_FW_Cmd.runConfigure_Ramp_Scenario();
        end
    end
    % Clear results 
    MMIC.CTRX_FW_Cmd.runClear_Results();

    % Configure RF Frequency 
    MMIC.CTRX_FW_Cmd.runConfigure_RF_Frequency();

    % Configure TX Power
    MMIC.CTRX_FW_Cmd.runConfigure_TX_Power();

    % Configure RX
    MMIC.CTRX_FW_Cmd.runConfigure_RX();

    % Execute_calibration 
%     MMIC.CTRX_FW_Cmd.runExecute_Calibration();
% 
%     % Get temp for each MMIC
%     MMIC.CTRX_FW_Cmd.Get_Temperature();
% 
%     disp([MMIC.name, ' Temperature Sensor 1: ', num2str(h.q2v(MMIC.CTRX_FW_Cmd.Results.Get_Temperature.Temp1,12,3)), '°C']);
%     disp([MMIC.name, ' Temperature Sensor 2: ', num2str(h.q2v(MMIC.CTRX_FW_Cmd.Results.Get_Temperature.Temp2,12,3)), '°C']);
%     disp([MMIC.name, ' Temperature Sensor 3: ', num2str(h.q2v(MMIC.CTRX_FW_Cmd.Results.Get_Temperature.Temp3,12,3)), '°C']);

end