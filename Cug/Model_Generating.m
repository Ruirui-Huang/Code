clc
clear all
close all;

% ��ȡG����32x32x16��
load('d', 'G')
% ���߲���
times = 5;

for num = 1:times
    Randomwalk(num);
    clear all
    close all;
end
