clc
clear all;
close all;

times = 5;
nsx = 32;
nsy = 32;
nbz = 16;

load('d', 'G')

for num = 1:times
    file=['d:/Matlab/Data/', 'T', num2str(num), '.dat'];
    savefile = ['d:/Matlab/Data/', 'D', num2str(num), '.mat'];
    input = load(file);
    [modeling_m,modeling_n] = size(input);
    m = zeros(nsx * nsy * nbz,1);
    for i = 1:modeling_m
        m(input(i,1) + nsx * (input(i,2) - 1) + nsx * nsy * (input(i,3) - 1)) = input(i,4) * 1000;
    end
    d = G * m;
    save(savefile, 'd', 'm'); 
end
