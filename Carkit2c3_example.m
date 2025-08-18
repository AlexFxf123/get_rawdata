%% Carkit2c3 Example
% The following example can be executed on a Carkit Board containing 
% 2 CTRX8191F and one TC39xx Aurix.
% It configures CTRX A in Primary mode, CTRX B in secondary mode 
% and performs a radar-measurement using a ramp sequence,
% which has been generated and encoded in advance by the RDT
% (Ramp Design Tool).
% It reads the time data, process 1st and 2nd FFT and generate plots 
% dependent on plot-settings.
%
close all;
clear global
clear persistent
clear;

% Start from a clean state and add Strata for CTRX to the MATLAB path
run('../addStrataPath.m');
% Add ram FW path
run('../../ram_fw/addRamFwPath_91.m');

%% Interfaces
% This section creates the interface objects for the board, the mmic and
% the board extension
board = strata.Connection.withAutoAddress();    % default setup
% board = strata.Connection.withAutoAddress([10, 132, 174, 232]); 

[vid, pid]     = board.getIds();
boardName      = strata.BoardIdentifier.getBoardName(vid, pid);
boardExtension = board.getBridgeSpecificInterface('CtrxP2sBoardExtension');
h              = strata.CtrxHelperFunctions();
MMIC_A = struct(); 
MMIC_B = struct();

% Create Interface objects for each MMIC.
%  MMIC A
MMIC_A.name           = 'MMIC A';
MMIC_A.radarCtrx      = board.getIRadarCtrx(0);
MMIC_A.module         = board.getIModuleRadarCtrx(0);
MMIC_A.ipins          = MMIC_A.radarCtrx.getIPinsCtrx();
MMIC_A.ispiProt       = MMIC_A.radarCtrx.getICtrxSpiProtocol();
MMIC_A.ispiCmds       = MMIC_A.radarCtrx.getISpiCommands();

%  MMIC B
MMIC_B.name           = 'MMIC B';
MMIC_B.radarCtrx      = board.getIRadarCtrx(1);
MMIC_B.module         = board.getIModuleRadarCtrx(1);
MMIC_B.ipins          = MMIC_B.radarCtrx.getIPinsCtrx();
MMIC_B.ispiProt       = MMIC_B.radarCtrx.getICtrxSpiProtocol();
MMIC_B.ispiCmds       = MMIC_B.radarCtrx.getISpiCommands();

MMIC_A.CTRX_FW_Cmd       = CFWI.CTRX_FW_Cmd_Access_Wrapper(MMIC_A.radarCtrx);

% check for B11 
response = MMIC_A.CTRX_FW_Cmd.runGet_Version();
if response.FwVersionCode == 13430504 
    rmpath('..\..\ram_fw\8191_Ram_A_Release_0.2.0')
    run('../../ram_fw/addRamFwPath_91_B11.m');
    MMIC_A.CTRX_FW_Cmd       = CFWI.CTRX_FW_Cmd_Access_Wrapper(MMIC_A.radarCtrx);
end

MMIC_A.CTRX_FW_Cmd_Param = CFWI.CTRX_FW_Cmd_Param(MMIC_A.radarCtrx);
MMIC_B.CTRX_FW_Cmd       = CFWI.CTRX_FW_Cmd_Access_Wrapper(MMIC_B.radarCtrx);
MMIC_B.CTRX_FW_Cmd_Param = CFWI.CTRX_FW_Cmd_Param(MMIC_B.radarCtrx);

 
if (~strcmp(strata.getVersion(),board.getVersion()))
    warning('Strata version doesnot match with board image version')
end
 
%% Config:
% This section sets the parameters for the ram firmware commands using the
% configuration function. The ramp design file and the LO configuration are
% also set.
% 
% seq_file_A =  '../../ramp_designs/primary_all_tx';
% seq_file_B =  '../../ramp_designs/secondary_all_tx';
% seq_file_A =  '../../ramp_designs/ddm_0.2m_512_384_primary';
% seq_file_B =  '../../ramp_designs/ddm_0.2m_512_384_secondary';
% seq_file_A =  '../../ramp_designs/ddm_0.2m_512_384_test_hp_primary';
% seq_file_B =  '../../ramp_designs/ddm_0.2m_512_384_test_hp_secondary';
% seq_file_A =  '../../ramp_designs/ddm_0.2m_512_384_test_hp_rx_primary';
% seq_file_B =  '../../ramp_designs/ddm_0.2m_512_384_test_hp_rx_secondary';
% seq_file_A =  '../../ramp_designs/ddm_0.4m_512_384_test_hp_primary';
% seq_file_B =  '../../ramp_designs/ddm_0.4m_512_384_test_hp_secondary';




LO_config_A = bin2dec('1111'); % LOIN 2 Primary
LO_config_B = bin2dec('0100'); % LOIN 1 Secondary

LOIN_pwr_target_A = h.dBm2Qval(-2,8,7);

% Call a common configuration script for individual MMIC with parameters
% for settings which are changed between MMICs
[MMIC_A, config_A, dataProperties, dataSettings, processingConfig, radarInfo] = Carkit2c3_example_cfg(MMIC_A, boardName, LO_config_A, seq_file_A, 'Primary', LOIN_pwr_target_A); % configuring parameters for MMIC_A
[MMIC_B, config_B] = Carkit2c3_example_cfg(MMIC_B, boardName, LO_config_B, seq_file_B, 'Secondary'); % configuring parameters for MMIC_B

MMIC_A.CTRX_FW_Cmd.setConfig(MMIC_A.CTRX_FW_Cmd_Param);
MMIC_B.CTRX_FW_Cmd.setConfig(MMIC_B.CTRX_FW_Cmd_Param);

%% Low Power - Goto Operation sequence

% Setup_MMIC_operation (it also contains initial RX-calibration)
strata.Setup_MMIC_operation(MMIC_A, config_A, true);
strata.Setup_MMIC_operation(MMIC_B, config_B, true);

MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000'); 
MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000');
MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
MMIC_B.CTRX_FW_Cmd.runExecute_Calibration();

% RX calib A step 1
% MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001000000000'); 
% MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001000000000');
% MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
% MMIC_B.CTRX_FW_Cmd.runExecute_Calibration();
% % RX calib A step 2
% MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000100000000'); 
% MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000100000000');
% MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
% MMIC_B.CTRX_FW_Cmd.runExecute_Calibration();
% % RX calib B 
% MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000100000000000'); 
% MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000100000000000');
% MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
% MMIC_B.CTRX_FW_Cmd.runExecute_Calibration();
% % RX calib gain 
% MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001000000000000'); 
% MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001000000000000');
% MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
% MMIC_B.CTRX_FW_Cmd.runExecute_Calibration();

% Execute Goto operation for primary MMIC
MMIC_A.CTRX_FW_Cmd.runGoto_Operation();

% Execute Goto Operation for other MMICs
MMIC_B.CTRX_FW_Cmd.runGoto_Operation();

CALIB = true;
if CALIB == true
    %% Execute Warm up calibration, clock-triggered (LO and TX sub-calibration)
    % Set Calibration sub functions 
    MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001100011011'); % PRIMARY MMIC: Lo input power 
    MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001100001011');
%     MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000011011'); % PRIMARY MMIC: Lo input power 
%     MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000001011');
    % Call Execute calibration for secondary MMIC using Async start
    MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Start");
    % Execute Calibration command for Primary MMIC
    Calib_response_A = MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
    % Receive Execute calibration response for secondary MMIC using Async Finish
    Calib_response_B = MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Finish");
%     MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration();


%     % TX phase power-up calibration, part 1
%     MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000000100'); 
%     MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000000100');
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Start");
%     MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Finish");
%     % TX phase power-up calibration, part 2
%     MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000001000'); 
%     MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000001000');
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Start");
%     MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Finish");
%     % TX power calibration
%     MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000000001'); 
%     MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000000001');
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Start");
%     MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Finish");
%     % TX phase warm-up calibration
%     MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000000010'); 
%     MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000000000000010');
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Start");
%     MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
%     MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Finish");
end



%% Sequencing section
MMIC_A.module.configure(config_A.dataIndex, 1, dataProperties, true); % Configure the measurement. 'reorderToInterleavedFormat' is set to True by default for aurix.
MMIC_A.module.start(config_A.dataIndex); % Start the measurement

MMIC_B.module.configure(config_B.dataIndex, 1, dataProperties, true); % Configure the measurement. 'reorderToInterleavedFormat' is set to True by default for aurix.
MMIC_B.module.start(config_B.dataIndex); % Start the measurement

% Start Ramp Scenario for secondary MMICs
MMIC_B.CTRX_FW_Cmd.runStart_Ramp_Scenario();

% Start Ramp Scenario for primary MMIC
MMIC_A.CTRX_FW_Cmd.runStart_Ramp_Scenario();

% Finish Ramp scenario for all MMIC
MMIC_A.CTRX_FW_Cmd.runFinish_Ramp_Scenario();
MMIC_B.CTRX_FW_Cmd.runFinish_Ramp_Scenario();

% Get Frame Data
[Frame_1, Timestamp1, virtualChannel1, statusCode1] = board.getFrame(2000); % read received data (timeout = 2000msec)
[Frame_2, Timestamp2, virtualChannel2, statusCode2] = board.getFrame(2000); % read received data (timeout = 2000msec)

if virtualChannel1 == 0
    Frame_A = Frame_1;
    Frame_B = Frame_2;
else
    Frame_A = Frame_2;
    Frame_B = Frame_1;
end
% % 将数据写入文件
% if true
%     fid=fopen("bif.bin","wb");
%     fwrite(fid,Frame_A','uint8');
%     fclose(fid);
% end

%% Get Temperature For Each MMIC
MMIC_A.CTRX_FW_Cmd.Get_Temperature();
MMIC_B.CTRX_FW_Cmd.Get_Temperature();

MONITOR = false;
if MONITOR == true
    %% Execute Monitoring, clock Triggered
    % Set Monitoring sub functions 
    MMIC_A.CTRX_FW_Cmd_Param.Execute_Monitoring.MonitoringSubFuncId  = bin2dec('000000101010111'); 
    MMIC_B.CTRX_FW_Cmd_Param.Execute_Monitoring.MonitoringSubFuncId  = bin2dec('000000101010111');
    % Call Execute Monitoring for secondary MMIC using Async start
    MMIC_B.CTRX_FW_Cmd.runExecute_Monitoring("Execute_Directly_FW_CMD_Async_Start");
    % Execute Monitoring command for Primary MMIC
    Mon_response_A = MMIC_A.CTRX_FW_Cmd.runExecute_Monitoring();
    % Receive Execute Monitoring response for secondary MMIC using Async Finish
    Mon_response_B = MMIC_B.CTRX_FW_Cmd.runExecute_Monitoring("Execute_Directly_FW_CMD_Async_Finish");
end

%% Goto_Low_Power for Secondary MMICs
MMIC_B.CTRX_FW_Cmd.runGoto_Low_Power();

% Goto_Low_power for Primary MMIC
MMIC_A.CTRX_FW_Cmd.runGoto_Low_Power();

strata.Plot_Frame_Data(config_A, Frame_A, 1, MMIC_A);
strata.Plot_Frame_Data(config_B, Frame_B, 1, MMIC_B);

disp 'Script finished'