function [MMIC, config, dataProperties, dataSettings, processingConfig, radarInfo, antennaConfig] = Carkit2c3_example_cfg(MMIC, boardName, LO_Config, rampDesignfile, MMIC_type, LOIN_Pwr_target)
    %% Carkit2C3 Example Configuration:
    % The configuration function provides the parameter values for all
    % firmware commands used in the example script.

    if nargin > 5
        LOIN_power  = LOIN_Pwr_target;
    else
        LOIN_power = strata.CtrxHelperFunctions.dBm2Qval(-2,8,7); % Default value = 128
    end
    
    % TX configuration:
%     f_static = 79.65;                   % static frequency in GHz before ramp sequence starts
%     f_lock = 80.988002;                 % Upper frequency of the RF modulation bandwidth in GHz，最高频率
%     f_bw = 2.499999;                    % RF modulation bandwidth in GHz，带宽
    f_static = 76.5;                   % static frequency in GHz before ramp sequence starts
    f_lock = 77.00;                 % Upper frequency of the RF modulation bandwidth in GHz，最高频率
    f_bw = 1.000;                    % RF modulation bandwidth in GHz，带宽
    [nmod, NCW, RampBW] = strata.CtrxHelperFunctions.calculateFreqParam( f_lock, f_bw, f_static);
    
    % data sheet上是0~15dB,实际上可以到20dB
    TX1_plevel = [10, 3, 0, 10];        % power back-off level 1-4 for TX1 in dB
    TX2_plevel = [10, 3, 0, 10];        % power back-off level 1-4 for TX2 in dB
    TX3_plevel = [10, 3, 0, 10];        % power back-off level 1-4 for TX3 in dB
    TX4_plevel = [10, 3, 0, 10];        % power back-off level 1-4 for TX4 in dB
    TX1_PA_Slope_Scaling_Factor = 1;    % Slope cscaling factor for TX1
    TX2_PA_Slope_Scaling_Factor = 1;    % Slope cscaling factor for TX2
    TX3_PA_Slope_Scaling_Factor = 1;    % Slope cscaling factor for TX3
    TX4_PA_Slope_Scaling_Factor = 1;    % Slope cscaling factor for TX4
    
    % TX power and phase index used for execute_monitoring command
    PL_TX1 = 0;                         % TX1 power level index before ramp sequence starts
    PL_TX2 = 0;                         % TX2 power level index before ramp sequence starts
    PL_TX3 = 0;                         % TX3 power level index before ramp sequence starts
    PL_TX4 = 0;                         % TX4 power level index before ramp sequence starts
    % 
    Phase_TX1_Index = 0;                % TX1 phase index: Nphase_Index=round((Ï†[deg]*points)/360) where points = 128 (for A-step), 256 (for B-step)
    Phase_TX2_Index = 0;                % TX2 phase index: Nphase_Index=round((Ï†[deg]*points)/360) where points = 128 (for A-step), 256 (for B-step)
    Phase_TX3_Index = 0;                % TX3 phase index: Nphase_Index=round((Ï†[deg]*points)/360) where points = 128 (for A-step), 256 (for B-step)
    Phase_TX4_Index = 0;                % TX4 phase index: Nphase_Index=round((Ï†[deg]*points)/360) where points = 128 (for A-step), 256 (for B-step)
    
    % RX configuration:
    % Aurix2G LVDS RIF maximum baud rate is 400mbps, which means it does
    % not support osrSel = 0 of 50 MS/S as per specifications
    osrSel = 2;             % output sample rate: 0 (50 MS/s), 1 (33.33 MS/s), 2 (25 MS/s), 3 (20 MS/s), 4 (16.67 MS/s), 5 (12.5 MS/s), 6 (10 MS/s), 7 (8.33 MS/s), 8 (6.25 MS/s), 9 (5 MS/s)
    dataWidthSel = 3;       % bitwidth of HSRIF data: 2 (12bits), (Value range: 1..3 (10..14bits in 2bit steps)
    csi2DataRate = 1;       % (value range 0-38) 0: 1200Mbits/s, 1: 1000 Mbits/s, 2: 933 Mbits/s, 3: 800 Mbits/s, 4: 700 Mbits/s, 5: 667 Mbits/s, 6: 600 Mbits/s, 7: 560 Mbits/s, 9: 500 Mbits/sâ€¦ See User Manual
    csi2StartMode = 0;      % 0: immediately after payload segment, 1: at next payload segment
    % During a ramp scenario, gain and high pass filter settings are
    % controlled by the sequencer according to CONFIG0 and CONFIG1 settings
    % of the the sequencer program's segment opcodes.
    gain = 7;               % gain setting: 3 (+15dB), (Value range: 0..6 (24..6dB in 3dB steps), 7 (0dB), 9..11 (-6..-18 in 6dB steps))
	HP1 = 4;            % 0: 200kHz, 1: 400 kHz, 2: 800 kHz, 3: 1600 kHz, 4: 3200kHz
	HP2 = 5;            % 0: 120kHz, 1: 240 kHz, 2: 480 kHz, 3: 960 kHz, 4: 1920 kHz, 5: 3840 kHz
	HP2En = 1;          % 0: HP2 disable (bypass), 1: HP2 enable    
    % The HP filter settings above are also used by execute_monitoring
    
    % Ramp configuration:
    config.sequencerFile = [rampDesignfile '.dat']; % sequencer program to download into sequencer memory
    rampScenarioSetupAddress = hex2dec('0');    % Sequencer setup structure start address of sequencer program
    
    % DMUX configuration:
    configMask = bin2dec('11');             % b0: DMUX1, b1: DMUX2
    dmuxDir = [1, 1];                     % Direction of CTRX DMUX1-2 pins (0: Input, 1: Output)
    dmuxPulseDuration = [63, 63];           % Pulse duration of DMUX1-2 (0: disabled, 3..63: (n+1)*5ns)
    dmuxSignalMap = [hex2dec('A0'), hex2dec('E9')]; % Example: DMUX1=0xA0: RX Payload_gate_level, DMUX2=0xE9: DMUXA_level
    
    % Plot configuration:
    config.plotTimeData = true;                 % true: time data plots generated, false: time data plots NOT generated
    config.plotFFT1 = false;                     % true: FFT1 plots generated, false: FFT1 plots NOT generated
    config.plotFFT2 = true;                     % true: RD plots generated, false: RD plots NOT generated
    config.rxPlotMask = [true,true,true,true];  % mask to define, which RX channels shall be plotted [RX1,RX2,RX3,RX4]
    
    %% Calculating waveform parameters:
    config.nSamples = 512;              % samples in a ramp
    total_ramps = 384;                  % chirps num
    Waveform.Tpayload = 20.48e-6;
    Waveform.ramps = total_ramps;
    
    config.nRamps = Waveform.ramps;  % number of ramps
    osr = [50, 33.33, 25, 20, 16.67, 12.5, 10, 8.33, 6.25, 5]; % Possible RX output sample rate values in MHz/us
    config.osrValue = osr(osrSel+1);
    
    %% Conversion of above config values to FW command parameters:
    coff = 2^7;
    % Configure_TX_Power
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx1Plvl1 = TX1_plevel(1) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx2Plvl1 = TX2_plevel(1) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx3Plvl1 = TX3_plevel(1) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx4Plvl1 = TX4_plevel(1) * coff;
    
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx1Plvl2 = TX1_plevel(2) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx2Plvl2 = TX2_plevel(2) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx3Plvl2 = TX3_plevel(2) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx4Plvl2 = TX4_plevel(2) * coff;
    
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx1Plvl3 = TX1_plevel(3) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx2Plvl3 = TX2_plevel(3) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx3Plvl3 = TX3_plevel(3) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx4Plvl3 = TX4_plevel(3) * coff;
    
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx1Plvl4 = TX1_plevel(4) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx2Plvl4 = TX2_plevel(4) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx3Plvl4 = TX3_plevel(4) * coff;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx4Plvl4 = TX4_plevel(4) * coff;
    % 1~1280，无符号Q8.8格式
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx1PaSlopeScaleFact = TX1_PA_Slope_Scaling_Factor * coff*2;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx2PaSlopeScaleFact = TX2_PA_Slope_Scaling_Factor * coff*2;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx3PaSlopeScaleFact = TX3_PA_Slope_Scaling_Factor * coff*2;
    MMIC.CTRX_FW_Cmd_Param.Configure_TX_Power.Tx4PaSlopeScaleFact = TX4_PA_Slope_Scaling_Factor * coff*2;
    
    % Configure_RX
    MMIC.CTRX_FW_Cmd_Param.Configure_RX.Gain = gain;
    MMIC.CTRX_FW_Cmd_Param.Configure_RX.DataWidth = dataWidthSel;
    MMIC.CTRX_FW_Cmd_Param.Configure_RX.DecSel = osrSel;
    MMIC.CTRX_FW_Cmd_Param.Configure_RX.HsrifCsi2DataRate = csi2DataRate;
    MMIC.CTRX_FW_Cmd_Param.Configure_RX.HsrifStartMode = csi2StartMode;
    
    % Configure_Ramp_Scenario
    MMIC.CTRX_FW_Cmd_Param.Configure_Ramp_Scenario.Startoffset = rampScenarioSetupAddress;
    
    % Configure_RF_Frequency
    MMIC.CTRX_FW_Cmd_Param.Configure_RF_Frequency.Nmod = nmod;
    MMIC.CTRX_FW_Cmd_Param.Configure_RF_Frequency.Ncw = NCW;
    MMIC.CTRX_FW_Cmd_Param.Configure_RF_Frequency.Bc = 1;
    MMIC.CTRX_FW_Cmd_Param.Configure_RF_Frequency.Rampbw = RampBW;
    
    % Configure_DMUX
    MMIC.CTRX_FW_Cmd_Param.Configure_DMUX.ConfigMask = configMask;
    MMIC.CTRX_FW_Cmd_Param.Configure_DMUX.Dmux1Dir = dmuxDir(1);
    MMIC.CTRX_FW_Cmd_Param.Configure_DMUX.Dmux2Dir = dmuxDir(2);
    MMIC.CTRX_FW_Cmd_Param.Configure_DMUX.Dmux1PulseDurationExt = dmuxPulseDuration(1);
    MMIC.CTRX_FW_Cmd_Param.Configure_DMUX.Dmux2PulseDurationExt = dmuxPulseDuration(2);
    MMIC.CTRX_FW_Cmd_Param.Configure_DMUX.Dmux1AltSignal = dmuxSignalMap(1);
    MMIC.CTRX_FW_Cmd_Param.Configure_DMUX.Dmux2AltSignal = dmuxSignalMap(2);
    
    config.dmuxDir = dmuxDir;
    
    % Configure_MMIC_Clock 
    MMIC.CTRX_FW_Cmd_Param.Configure_MMIC_Clock.ClkoutSourceResistance = 1; % 0 = 50 ohm, 1 = 40 ohm
    MMIC.CTRX_FW_Cmd_Param.Configure_MMIC_Clock.ClkoutBiasVoltage = 0;      % 0 = 0V (CLKOUT connecnted to ground/VSS), 1 = 1.2V (CLKOUT connected to 1.2V/VDD)
    
    % Clear Result area
    MMIC.CTRX_FW_Cmd_Param.Clear_Results.ClrAreasMsk = 0b00011000;
    
    % Execute_Monitoring
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.DetailResult = 0;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.Nmod = nmod;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.TxChMask = bin2dec('1111');
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.DecSel = osrSel;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.Hp1 = HP1;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.Hp2En = HP2En;
    if MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.Hp2En == 1
        MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.Hp2 = HP2;
    end
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PlTx1 = PL_TX1;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PhaseTx1 = Phase_TX1_Index;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PlTx2 = PL_TX2;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PhaseTx2 = Phase_TX2_Index;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PlTx3 = PL_TX3;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PhaseTx3 = Phase_TX3_Index;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PlTx4 = PL_TX4;
    MMIC.CTRX_FW_Cmd_Param.Execute_Monitoring.PhaseTx4 = Phase_TX4_Index;
    %% Additional config parameters for dedicated FW commands
    % Measure_TX
    MMIC.CTRX_FW_Cmd_Param.Measure_TX.ChMask = bin2dec('1111');   % all TX
    MMIC.CTRX_FW_Cmd_Param.Measure_TX.Mode = 0;      % 0: PLD forward direction, 1: PLD reverse direction, 2: ADC forward power and phase
    
    % Execute_Calibration
    switch MMIC_type
        case 'Primary'
            MMIC.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000'); % (RX sub-calibration)
        case 'Secondary'
            MMIC.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000'); % (RX sub-calibration)
        case 'Standalone'
            MMIC.CTRX_FW_Cmd_Param.Execute_Calibration.CalibSubFuncId = bin2dec('001101100000000');
    end
    MMIC.CTRX_FW_Cmd_Param.Execute_Calibration.TxChPowIdx = hex2dec('FFFF');     % enable power calibration for all power levels at all TX channels
    MMIC.CTRX_FW_Cmd_Param.Execute_Calibration.RefTempIdx = 0;                   % no reference temperature. 0: calibrate regardless of current temperature. See UM for setting different value from 0.
    MMIC.CTRX_FW_Cmd_Param.Execute_Calibration.LimitTemp = 0;                    % Calibration shall be called if |latest temperature - reference temperature| > LimitTemp (scaled in Q12.3 format), 0: calibrate regardless of current temperature. See UM for setting different value from 0.
    
    MMIC.CTRX_FW_Cmd_Param.Finish_Ramp_Scenario.Timeout = 0.1/5e-9;      % timeout in 5ns
    
    % Initialize
    config.hsrif = 1;               % 0: CSI-2 , 1: LVDS
    hsrifConfig = bin2dec('0010000110');   % Default value (0b0010000111), b0: Global CRC enable (CSI-2), b1: CRC checksum calculation data word bit order(LVDS, CSI-2)... See user manual for details
    
    MMIC.CTRX_FW_Cmd_Param.Initialize.Index = [18,  21,  209, 210]; % 18: LVDS/CSI-2 selection, 20: Logical to Physical lane mapping, 21: HSRIF Configuration, 22: CSI2 lane enable, 209: LO config, 210: LOIN Power 
    MMIC.CTRX_FW_Cmd_Param.Initialize.Value = [config.hsrif,  hsrifConfig,  LO_Config, LOIN_power];
    MMIC.CTRX_FW_Cmd_Param.Initialize.Length = size(MMIC.CTRX_FW_Cmd_Param.Initialize.Index, 2);
    
    dataWidth = [10, 12, 14]; % Possible RX data width values in bits
    
    switch MMIC_type
        case 'Primary'
            config.dataIndex = 0;
        case 'Secondary'
            config.dataIndex = 1;
    end
    config.dataWidthValue = 16;

    %% Aurix config

    NoRx = 4;
    
    % configure data properties / size
    dataProperties.format = strata.DataFormat.Q15;                         % [1]    set the precision format of the received time domain signals, Q15 - 16 bit signed fixed point precision - real valued data (default)
    dataProperties.rxChannels = NoRx;                                      % [1]    set number of (enabled) receive channels 
    dataProperties.ramps = config.nRamps;                                  % [1]    set total number of (used) ramp segments
    dataProperties.samples = config.nSamples;                              % [1]    set number of samples captured during the payload segment
    dataProperties.channelSwapping = 0;                                    % [1]    set channel swapping: swap adjacent pair of rx channels fed into AURIX rif interface
    dataProperties.bitWidth = dataWidth(dataWidthSel);                     % [1]    set data bit width: 12 bit or 14 bit

    crcEnabled = true;                                                     % enable (true) or disable (false) CRC
    dataSettings.flags = crcEnabled * strata.IData.FLAGS_CRC_ENABLED;    
    
    %% Setup FFT settings
    processingConfig.fftSteps = 0;                                           % [1]   set option to perform a FFT on captured time data.

    processingConfig.fftFormat = strata.DataFormat.ComplexQ31;               % [1]   set output data format of the FFTs, only Real* or Complex*: 'ComplexQ31' 32 bit signed fixed point precision (default) -> Re{32bit} + Imag{32bit}
    processingConfig.nciFormat = strata.DataFormat.Disabled;                 % [1]   shall be set to 'Disabled' (default)
    processingConfig.virtualChannels = strata.IfxRsp.VirtualChannel.RawData; % [1]   shall be set to 'RawData' (default)

    %FFT setting (first FFT)
    processingConfig.fftSettings(1).size = 0;                                % 0 = default number of samples (= smallest power of 2 greater than or equal to number of samples)
    processingConfig.fftSettings(1).window = strata.IfxRsp.FftWindow.Hann;   % set window function to be applied: 'Hann' (default)
    processingConfig.fftSettings(1).windowFormat = strata.DataFormat.Q31;    % set format of the window function data : 'Q31' (default)
    processingConfig.fftSettings(1).exponent = 0;                            % right shift of the output data: '0' no shift is performed (default)
    processingConfig.fftSettings(1).acceptedBins = 0;                        % 0 = all (disable rejection), otherwise number of accepted bins from the beginning

    % INPLACE: overwrite previous stored input time data
    % DISCARD_HALF: specify whether symmetric second half of FFT should be discarded (acceptedBins has to be set to 0) - only valid if time domain signal is defined as real valued format(Q15).
    processingConfig.fftSettings(1).flags = bitor(strata.IfxRsp.FFT_FLAGS.INPLACE, strata.IfxRsp.FFT_FLAGS.DISCARD_HALF);
 
    %FFT setting (second FFT)
    processingConfig.fftSettings(2).size = 0;
    processingConfig.fftSettings(2).window = strata.IfxRsp.FftWindow.Hann;   % set window function to be applied: 'Hann' (default)
    processingConfig.fftSettings(2).windowFormat = strata.DataFormat.Q31;    % set format of the window function data : 'Q31' (default)
    processingConfig.fftSettings(2).exponent = 0;                            % right shift of the output data: '0' no shift is performed (default)
    processingConfig.fftSettings(2).acceptedBins = 0;                        % 0 = all (disable rejection), otherwise number of accepted bins from the beginning

    % INPLACE: overwrite previous stored input range FFT(1) data
    processingConfig.fftSettings(2).flags = strata.IfxRsp.FFT_FLAGS.INPLACE;
    
    processingConfig.dbfSetting(1).angles = 0;
    processingConfig.dbfSetting(2).angles = 0;                                          
                                                                                    
    processingConfig.virtualChannels = strata.IfxRsp.VirtualChannel.RawData;  % [1]   shall be set to 'RawData' (default)

    % configure/set processing (SPU)
    radarInfo.txChannels = 4;                                                 % [1]    set number of (enabled) transmit channels  
    radarInfo.virtualAnt = 4;                                                 % [1]    set number of virtual receive channels
    radarInfo.rampsPerTx = total_ramps;                                       % [1]    set number of (used) ramp segments

    % Note: maxRange and maxVelocity must be set properly if PeakDetection
    % is performed on Aurix.
    radarInfo.maxRange = 0;                                                   % [m]    set max. (unambiguous) range acc. to selected IF bandwidth
    radarInfo.maxVelocity = 0;                                                % [m/s]  set max. (unambiguous) velocity acc. to selected ramp profile
 
    
end

