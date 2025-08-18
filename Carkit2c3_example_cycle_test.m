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
% board = strata.Connection.withAutoAddress([169, 254, 1, 101]); 

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

% seq_file_A =  '../../ramp_designs/Primary_Distributed_TDMA_TX1_TX3';
% seq_file_B =  '../../ramp_designs/Secondary_Distributed_TDMA_TX2_TX4';
% seq_file_A =  '../../ramp_designs/test_data_primary';
% seq_file_B =  '../../ramp_designs/test_data_secondary';
% seq_file_A =  '../../ramp_designs/primary_all_tx';
% seq_file_B =  '../../ramp_designs/secondary_all_tx';
% seq_file_A =  '../../ramp_designs/ddm_primary_test';
% seq_file_B =  '../../ramp_designs/ddm_secondary_test';
% seq_file_A =  '../../ramp_designs/ddm_primary';
% seq_file_B =  '../../ramp_designs/ddm_secondary';
seq_file_A =  '../../ramp_designs/ddm_ccm_primary2';
seq_file_B =  '../../ramp_designs/ddm_ccm_secondary2';


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
strata.Setup_MMIC_operation(MMIC_A, config_A, true);       % false表示不导入.dat文件
strata.Setup_MMIC_operation(MMIC_B, config_B, true);       % false表示不导入.dat文件

% Read results from memory
MMIC_A.CTRX_FW_Cmd_Param.Read_Memory.Region = 12;          		% Memory region，16进制为0C，相当于十进制12
MMIC_A.CTRX_FW_Cmd_Param.Read_Memory.Passkey = 0;
MMIC_A.CTRX_FW_Cmd_Param.Read_Memory.FromAddr = 0;             % Start Address of the Memory
MMIC_A.CTRX_FW_Cmd_Param.Read_Memory.Length = 30;          		% Length of the data word to be read       
resp = MMIC_A.CTRX_FW_Cmd.runRead_Memory();                  			 % Firmware Function call to read
%     orig_word = bitand(resp.DataWord,uint32(0xFFFF));
%     disp(['get memory', orig_word]);

% 从此处开始循环
while 1
    total_times = 100;
    for i = 1:1:total_times
        % Execute Goto operation for primary MMIC
        MMIC_A.CTRX_FW_Cmd.runGoto_Operation();
        
        % Execute Goto Operation for other MMICs
        MMIC_B.CTRX_FW_Cmd.runGoto_Operation();
        
        %% Execute Warm up calibration, clock-triggered (LO and TX sub-calibration)
        
%         % Set Calibration sub functions 
%         MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001100011011'); % PRIMARY MMIC: Lo input power 
%         MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001100001011');
%         
%         % Call Execute calibration for secondary MMIC using Async start
%         MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Start");
%         
%         % Execute Calibration command for Primary MMIC
%         Calib_response_A = MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
%         
%         % Receive Execute calibration response for secondary MMIC using Async Finish
%         Calib_response_B = MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Finish");

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
%         tic;
%         [Frame_1, Timestamp1, virtualChannel1, statusCode1] = board.getFrame(2000); % read received data (timeout = 2000msec)
%         [Frame_2, Timestamp2, virtualChannel2, statusCode2] = board.getFrame(2000); % read received data (timeout = 2000msec)
%         toc;
%         
%         if virtualChannel1 == 0
%             Frame_A = Frame_1;
%             Frame_B = Frame_2;
%         else
%             Frame_A = Frame_2;
%             Frame_B = Frame_1;
%         end
        
        %% Get Temperature For Each MMIC
        MMIC_A.CTRX_FW_Cmd.Get_Temperature();
        disp([MMIC_A.name, ' Temperature Sensor 1: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp1,12,3)), '°C']);
        disp([MMIC_A.name, ' Temperature Sensor 2: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp2,12,3)), '°C']);
        disp([MMIC_A.name, ' Temperature Sensor 3: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp3,12,3)), '°C']);
        MMIC_B.CTRX_FW_Cmd.Get_Temperature();
        disp([MMIC_B.name, ' Temperature Sensor 1: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp1,12,3)), '°C']);
        disp([MMIC_B.name, ' Temperature Sensor 2: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp2,12,3)), '°C']);
        disp([MMIC_B.name, ' Temperature Sensor 3: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp3,12,3)), '°C']);
        
        
        %% Execute Monitoring, clock Triggered
        
%         % Set Monitoring sub functions 
%         MMIC_A.CTRX_FW_Cmd_Param.Execute_Monitoring.MonitoringSubFuncId  = bin2dec('000000101010111'); 
%         MMIC_B.CTRX_FW_Cmd_Param.Execute_Monitoring.MonitoringSubFuncId  = bin2dec('000000101010111');
%         
%         % Call Execute Monitoring for secondary MMIC using Async start
%         MMIC_B.CTRX_FW_Cmd.runExecute_Monitoring("Execute_Directly_FW_CMD_Async_Start");
%         
%         % Execute Monitoring command for Primary MMIC
%         Mon_response_A = MMIC_A.CTRX_FW_Cmd.runExecute_Monitoring();
%         
%         % Receive Execute Monitoring response for secondary MMIC using Async Finish
%         Mon_response_B = MMIC_B.CTRX_FW_Cmd.runExecute_Monitoring("Execute_Directly_FW_CMD_Async_Finish");
        
        %% Goto_Low_Power for Secondary MMICs
        MMIC_B.CTRX_FW_Cmd.runGoto_Low_Power();
        
        % Goto_Low_power for Primary MMIC
        MMIC_A.CTRX_FW_Cmd.runGoto_Low_Power();
    
    
    % strata.(config_A, Frame_A, 4, MMIC_A);
    % strata.Plot_Frame_Data(config_B, Frame_B, 4, MMIC_B);
    end
    disp 'finish one cycle!'
end
