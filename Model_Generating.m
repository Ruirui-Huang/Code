clc
clear all
close all;

% 读取G，（32x32x16）
load('d', 'G')
% 游走步数
times = 5;

for num = 1:times
    Randomwalk(num);
    clear all
    close all;
end
