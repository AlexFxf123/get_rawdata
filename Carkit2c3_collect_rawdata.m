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
seq_file_A =  '../../ramp_designs/ddm_0.2m_512_384_primary';
seq_file_B =  '../../ramp_designs/ddm_0.2m_512_384_secondary';
% seq_file_A =  '../../ramp_designs/ddm_0.2m_512_384_test_primary';
% seq_file_B =  '../../ramp_designs/ddm_0.2m_512_384_test_secondary';
% seq_file_A =  '../../ramp_designs/ddm_0.4m_512_384_test_primary';
% seq_file_B =  '../../ramp_designs/ddm_0.4m_512_384_test_secondary';
% seq_file_A =  '../../ramp_designs/ddm_ccm_0.45m_512_384_primary';
% seq_file_B =  '../../ramp_designs/ddm_ccm_0.45m_512_384_secondary';
% seq_file_A =  '../../ramp_designs/ddm_ccm_0.75m_512_384_primary';
% seq_file_B =  '../../ramp_designs/ddm_ccm_0.75m_512_384_secondary';

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

% 从此处开始循环
COLLECT_DATA = 1;           % 采集原始数据开关，默认1采集
COLLECT_CAMERA = 0;         % 采集摄像头开关，默认1采集
clip_count = 0;             % 循环计数
total_times = 100;          % 单次循环采集的帧数
if COLLECT_CAMERA
    vid = videoinput('winvideo',2,'YUY2_1280x960');
    set(vid,'ReturnedColorSpace','rgb');
    preview(vid);
end

while 1
    clip_count = clip_count + 1;
    if COLLECT_DATA
        file_path = strcat('20250818_test_ddm_0.2m_',num2str(clip_count));
        mkdir (file_path);
    end
    for i = 1:1:total_times
        % RX-calibration
        MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000'); 
        MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000');
        MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
        MMIC_B.CTRX_FW_Cmd.runExecute_Calibration();

        % Execute Goto operation for primary MMIC
        MMIC_A.CTRX_FW_Cmd.runGoto_Operation();
        % Execute Goto Operation for other MMICs
        MMIC_B.CTRX_FW_Cmd.runGoto_Operation();
        
        %% Execute Warm up calibration, clock-triggered (LO and TX sub-calibration)
        % Set Calibration sub functions 
        MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001100011011'); % PRIMARY MMIC: Lo input power 
        MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('000001100001011');
%         MMIC_A.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000'); % PRIMARY MMIC: Lo input power 
%         MMIC_B.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000');
        % Call Execute calibration for secondary MMIC using Async start
        MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Start");
        % Execute Calibration command for Primary MMIC
        Calib_response_A = MMIC_A.CTRX_FW_Cmd.runExecute_Calibration();
        % Receive Execute calibration response for secondary MMIC using Async Finish
        Calib_response_B = MMIC_B.CTRX_FW_Cmd.runExecute_Calibration("Execute_Directly_FW_CMD_Async_Finish");

        %% Sequencing section
        MMIC_A.module.configure(config_A.dataIndex, 1, dataProperties, true); % Configure the measurement. 'reorderToInterleavedFormat' is set to True by default for aurix.
        MMIC_A.module.start(config_A.dataIndex); % Start the measurement
        
        MMIC_B.module.configure(config_B.dataIndex, 1, dataProperties, true); % Configure the measurement. 'reorderToInterleavedFormat' is set to True by default for aurix.
        MMIC_B.module.start(config_B.dataIndex); % Start the measurement
        
        % Start Ramp Scenario for secondary MMICs
        MMIC_B.CTRX_FW_Cmd.runStart_Ramp_Scenario();
        % Start Ramp Scenario for primary MMIC
        MMIC_A.CTRX_FW_Cmd.runStart_Ramp_Scenario();

        % % 获取当前UTC时间的datetime对象
        % utcTime = datetime('now','TimeZone','UTC');
        % % 转换为POSIX时间（秒）
        % posixTime = posixtime(utcTime);
        % % 转换为毫秒级时间戳
        % utcMsTimestamp = round(posixTime * 1000);

        % Finish Ramp scenario for all MMIC
        MMIC_A.CTRX_FW_Cmd.runFinish_Ramp_Scenario();
        MMIC_B.CTRX_FW_Cmd.runFinish_Ramp_Scenario();

        % Get Frame Data
        [Frame_1, Timestamp1, virtualChannel1, statusCode1] = board.getFrame(2000); % read received data (timeout = 2000msec)
        [Frame_2, Timestamp2, virtualChannel2, statusCode2] = board.getFrame(2000); % read received data (timeout = 2000msec)
        
        if COLLECT_DATA
            % Save Frame Data
            if virtualChannel1 == 0
                MMIC_A_file = strcat('./',file_path, '/', num2str(i), '_A.bin');
                fid = fopen(MMIC_A_file, "wb");
                fwrite(fid, Frame_1, 'uint8');
                fclose(fid);
                MMIC_B_file = strcat('./',file_path, '/', num2str(i), '_B.bin');
                fid = fopen(MMIC_B_file, "wb");
                fwrite(fid, Frame_2, 'uint8');
                fclose(fid);
            else
                MMIC_A_file = strcat('./',file_path, '/', num2str(i), '_A.bin');
                fid = fopen(MMIC_A_file, "wb");
                fwrite(fid, Frame_2, 'uint8');
                fclose(fid);
                MMIC_B_file = strcat('./',file_path, '/', num2str(i), '_B.bin');
                fid = fopen(MMIC_B_file, "wb");
                fwrite(fid, Frame_1, 'uint8');
                fclose(fid);
            end
        end

        if COLLECT_CAMERA
            frame = getsnapshot(vid); 
            imwrite(frame,strcat('./',file_path, '/', num2str(i),'.jpg'),'jpg'); 
        end

        %% Get Temperature For Each MMIC
        MMIC_A.CTRX_FW_Cmd.Get_Temperature();
%         disp([MMIC_A.name, ' Temperature Sensor 1: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp1,12,3)), '°C']);
%         disp([MMIC_A.name, ' Temperature Sensor 2: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp2,12,3)), '°C']);
%         disp([MMIC_A.name, ' Temperature Sensor 3: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp3,12,3)), '°C']);
        MMIC_B.CTRX_FW_Cmd.Get_Temperature();
%         disp([MMIC_B.name, ' Temperature Sensor 1: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp1,12,3)), '°C']);
%         disp([MMIC_B.name, ' Temperature Sensor 2: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp2,12,3)), '°C']);
%         disp([MMIC_B.name, ' Temperature Sensor 3: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp3,12,3)), '°C']);
        
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
    end
    clip_str = strcat('finish clip-', num2str(clip_count));
    disp (clip_str);
    disp([MMIC_A.name, ' Temperature Sensor 1: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp1,12,3)), '°C']);
    disp([MMIC_A.name, ' Temperature Sensor 2: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp2,12,3)), '°C']);
    disp([MMIC_A.name, ' Temperature Sensor 3: ', num2str(h.q2v(MMIC_A.CTRX_FW_Cmd.Results.Get_Temperature.Temp3,12,3)), '°C']);
    disp([MMIC_B.name, ' Temperature Sensor 1: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp1,12,3)), '°C']);
    disp([MMIC_B.name, ' Temperature Sensor 2: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp2,12,3)), '°C']);
    disp([MMIC_B.name, ' Temperature Sensor 3: ', num2str(h.q2v(MMIC_B.CTRX_FW_Cmd.Results.Get_Temperature.Temp3,12,3)), '°C']);
end
