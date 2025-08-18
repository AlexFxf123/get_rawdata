close all;clear;clc
%% 单个MMIC 20.48us * 25MSa/s * 2Byte(=16bit) * 4Rx * 256chirp

%% Path to the Binary file captured from the 2-chip cascade board
% dirName = './test_indoor/20250804_test_ddm_0.4m_indoor_10dB/';
dirName = './test_outdoor/20250807_test_ddm_0.2m_3/';
% dirName = './20250807_test_ddm_0.2m_indoor_15dB_hp/';
frame_num = 82;
fileName = strcat(num2str(frame_num),'_A.bin');


% 是否画一维FFT和二维FFT结果
plot_flag = 1;
% 读取雷达原始数据
filePath = strcat(dirName, fileName);
fp = fopen(filePath,'rb');
Sample_time = 20.48e-6;
fs = 25e6;
Sample_num = Sample_time*fs;
Rx_num = 4;
Chirps_num = 384;
MMIC_num = 1;
raw_data = fread(fp, 'int16', 'l');
fclose(fp);
% 读取图片数据
% imageName = strcat(num2str(frame_num),'.jpg');
% imagePath = strcat(dirName, imageName);
% pic = imread(imagePath);
% imshow(pic);

%%
data_reshaple = reshape(raw_data,Rx_num,Sample_num,Chirps_num); %[4,512,1,256]
%%

data_MMIC1 = data_reshaple;
adcOutFrame = permute(data_MMIC1, [2 3 1]);% [sample, chirp, rx_num] 512*256*4
adcOutFrame(1:30,:,:) = 0;
%% plot ADC data
figure();
for i = 1:4
    subplot(2,2,i);
    plot(adcOutFrame(:,:,1));
    grid on;
end
sgtitle('原始ADC数据');

% 高通滤波器测试
fc_high = 2000e3;       % 滤波器截止频率，通常为200~3200KHz
N = 6;
[b, a] = butter(N, fc_high/(fs/2), 'high');
figure;
for i = 1:4
    test = adcOutFrame(:,:,i);
    y = filter(b, a, test);
    subplot(2,2,i);
    plot(y);
    grid on;
%     adcOutFrame(:,:,i) = y;
end
sgtitle('高通滤波后ADC数据');

%%
rangeProfile = fft(adcOutFrame);
% rangeDoppler = fft(rangeProfile,[],2 );
rangeDoppler = fftshift(fft(rangeProfile,[],2 ),2);
%% channel acc
rangeDoppler_sum = zeros(Sample_num,Chirps_num);
for i = 1:Rx_num
    rangeDoppler_sum = rangeDoppler_sum+rangeDoppler(:,:,i);
end
rangeDoppler_sum_log = 20*log10(abs(rangeDoppler_sum));

if plot_flag
    figure();
    plot(20*log10(abs(rangeProfile(1:(Sample_num/2),:,1))));
    grid on;
    % R_label = 0:R_res:R_Max-R_res;
    % V_label = -V_Max+V_res:V_res:V_Max;
    figure();
    %     imagesc(V_label,R_label,rangeDoppler_sum_log)
    imagesc(rangeDoppler_sum_log);
    
    title('range-Doppler acc');
    xlabel('Doppler-Bin'); ylabel('Range-bin');
    
    %     figure;mesh(V_label,R_label,rangeDoppler_sum_log);colorbar;
    figure();
    mesh(rangeDoppler_sum_log);colorbar;
end


