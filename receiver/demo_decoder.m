% read data - 20 bit/s
file = 'data/commtest-erjinzhi3.wav';
% file_5000 = 'data/test_5000.wav';
[y,~] = audioread(file);
Fs = 192000;
y_f = bandpass(y, [8e4 9e4], Fs);

% sleep = 0.05s
y_01s_f = y_f(5472000:5587200);
figure(1)
plot(1:length(y_01s_f), y_01s_f);

xlim([0, 192000 * 0.6])
ylim([-0.0053, 0.0053])
xticks([0 192000 * 0.2 192000 * 0.4 192000 * 0.6 192000 * 0.8])
xticklabels({'0','100','200','300','400'})
yticks([-0.004 0 0.004])
yticklabels({'-1','0','1'})
xlabel('Time (ms)', 'FontSize',20)
ylabel('Amplitude (10^{-2})', 'FontSize',20)
set(gca,'FontSize',12.5); 
set(gcf, 'PaperSize', [8 6]);
set(gcf,'unit','normalized','position',[0.2,0.2,0.3,0.24]);
% saveas(1,'ejz_lc','pdf')

%%%%%%% signal preprocess
% detection
% for i = 1:length(y_01s_f)
%     if y_01s_f(i) > 0.0034
%        y_begin = i;
%        break 
%     end
% end 
% y_01s_f = y_01s_f(i+3659:end);

% denoise + 10log
y_01s_f = y_f(5469000:5597200);
y_01s_f_e = [];
window = 5000;
for i = 1:length(y_01s_f)-window+1
    y_01s_f_e(i) = 10*log(sum(y_01s_f(i:i+window-1).^2));
end

% mean window
y_01s_f_w = [];
window = 5000;
for i = 1:length(y_01s_f_e)-window+1
    y_01s_f_w(i) = sum(y_01s_f_e(i:i+window-1))/window;
end
y_01s_f_e_ = y_01s_f_e;
y_01s_f_e = y_01s_f_w;

y_num = 178;

% step
y_high = -59;
y_01s_step = [];
y_01s_step(1) = -45;
for i=2:length(y_01s_f_e)
    if y_01s_f_e(i) > y_high
        y_01s_step(i) = -45;
    else
        y_01s_step(i) = -68;
    end
end
% for i = 1:y_num
%     line([9600*i 9600*i],[-60 -20]);
% end

% step 抹平
y_01s_step2 = y_01s_step;
y_01s_count = [];
length_ = 1;
idx = 1;
for i = 2:length(y_01s_step2)
    if y_01s_step2(i) == y_01s_step2(i-1)
        length_ = length_ + 1;
    else 
        y_01s_count(idx) = length_;
        idx = idx + 1;
        length_ = 1;
    end
end

cycle_threshold = 3000;
y_decode = [];
y_idx = [];
idx = 1;
state = 1;
for i = 1:length(y_01s_count)
    if y_01s_count(i) > cycle_threshold
%         if y_01s_count(i) > 9600  % 连续状态
%             length_ = round(y_01s_count(i)/9600);
%             y_decode(idx:idx+length_-1) = state;
%             idx = idx + length_;
%             state = 1 - state;
%         else
        y_decode(idx) = state;
        y_idx(idx) = sum(y_01s_count(1:i));
        state = 1 - state;
        idx = idx + 1;
%         end
    end
end

% 验证
% plot(1:length(y_01s_step), y_01s_step, 'LineWidth', 2);
% ylim([-60 -20])
y_01s_step(1:1000) = -45;

figure(2)
p1=plot(1:length(y_01s_f_e_)-999, y_01s_f_e_(1000:end),'LineWidth', 1.5,'color',[43/246,140/246,190/246]);
hold on;
p2=plot(1:length(y_01s_f_w), y_01s_f_w, 'LineWidth', 1.5,'color',[4/246,90/246,141/246]);
p3=plot(1:length(y_01s_step), y_01s_step, 'LineWidth', 2,'color',[166/246,54/246,3/246]);
%plot(y_idx, y_high, 'or');

xlim([0, 192000 * 0.6])
ylim([-70, -38])
xticks([0 192000 * 0.2 192000 * 0.4 192000 * 0.6 192000 * 0.8])
xticklabels({'0','100','200','300','400'})
% yticks([-0.004 0 0.004])
% yticklabels({'-1','0','1'})
xlabel('Time (ms)', 'FontSize',20)
ylabel('Amplitude', 'FontSize',20)
set(gca,'FontSize',12.5); 
set(gcf, 'PaperSize', [8 6]);
set(gcf,'unit','normalized','position',[0.2,0.2,0.3,0.24]);
% saveas(2,'ejz_lc_decode','pdf')


% 周期内均值
% y_signal = [];
% y_data = [];
% y_data2 = [];
% data_threshole = -40;
% for i = 1:y_num
%     num_ = sum(y_01s_step(1+(9600*(i-1)):9600*i))/9600;
%     if num_ < data_threshole
%         y_data(i) = 0;
%     else
%         y_data(i) = 1;
%     end
%     y_data2(i) = y_01s_step(4800+9600*(i-1));
%     y_signal(i) = num_;
% %     figure(6)
% %     plot(1:9600, y_01s_step((y_begin+9600*(i-1)):(y_begin+9600*i-1)));
% %     ylim([-120 -40])
% end
% figure(4)
% plot(1:length(y_signal), y_signal);
% figure(5)
% plot(1:length(y_data), y_data);
% ylim([-1 2])


% %
% % preamble detection
% y_01_pd = [y_01s_step(80000:125400), y_01s_step(1:13200)];
% figure(3)
% plot(1:length(y_01_pd), y_01_pd);
% ylim([-120 -40])
% y_preamble = [-60 * ones(1, 9600), -100 * ones(1, 9600), -60 * ones(1, 9600),-100 * ones(1, 9600)];
% figure(2)
% plot(1:length(y_preamble), y_preamble);
% ylim([-120 -40])
% 
% % [lags, y_cross] = xcorr(y_01_pd, y_preamble);
% % figure(5)
% % plot(1:length(y_cross), y_cross);
% 
% % y_cross_ = [];
% % for i=1:(length(y_01_pd) - length(y_preamble) +1)
% %     stop_ = i+length(y_preamble)-1;
% %     y_corr = corrcoef(y_01_pd(i:stop_), y_preamble);
% %     y_corss_(i) = y_corr(1,1);
% % end
% % figure(4)
% % plot(1:length(y_corss_), y_corss_);
% 
% 
% % segmentation
% for i = 1:length(y_01s_step)
%     if y_01s_step(i) == -60
%        y_begin = i;
%        break 
%     end
% end 
% 
% y_num = floor((length(y_01s_step) - y_begin) / 9600);
% 
% % 周期内均值
% y_signal = [];
% y_data = [];
% y_data2 = [];
% data_threshole = -75;
% for i = 1:y_num
%     num_ = sum(y_01s_step((y_begin+9600*(i-1)):(y_begin+9600*i-1)))/9600;
%     if num_ < data_threshole
%         y_data(i) = 0;
%     else
%         y_data(i) = 1;
%     end
%     y_data2 = ;
%     y_signal(i) = num_;
% %     figure(6)
% %     plot(1:9600, y_01s_step((y_begin+9600*(i-1)):(y_begin+9600*i-1)));
% %     ylim([-120 -40])
% end
% figure(4)
% plot(1:length(y_signal), y_signal);
% figure(5)
% plot(1:length(y_data), y_data);
% ylim([-1 2])
% 
% % 周期内极值
% y_data2 = [];
% data_threshole2 = -100;
% for i = 1:y_num
%     num_ = min(y_01s_f_e((y_begin+9600*(i-1)):(y_begin+9600*i-1)));
%     if num_ < data_threshole2
%         y_data2(i) = 0;
%     else
%         y_data2(i) = 1;
%     end
% end
% figure(6)
% plot(1:length(y_data2), y_data2);
% ylim([-1 2])
% 
