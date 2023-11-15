clc
clear all
close all

%*********** data production ***********%
% 设置观测点个数
nx = 32;
ny = 32;
% 观测范围
Xrange = [0 640];
Yrange = [0 640];
% 640*640的范围内设置32*32个观测点
Xobserved = linspace(Xrange(1),Xrange(2),nx);
Yobserved = linspace(Yrange(1),Yrange(2),ny);

%*********** data production ***********%

%*********** underground modeling ***********%

nsx = 32; % x方向块体的个数
nsy = 32; % y方向块体的个数
nbz = 16; % z方向块体的个数

Xsrange = [0 640]; % X方向模型范围
Ysrange = [0 640]; % Y方向模型范围
Zsrange = [0 320]; % Y方向模型范围

position_nsx = linspace(Xsrange(1),Xsrange(2),nsx+1); % 块体的长，x方向
position_nsy = linspace(Ysrange(1),Ysrange(2),nsy+1); % 块体的宽，y方向
position_nbz = linspace(Zsrange(1),Zsrange(2),nbz+1); % 块体的高，z方向

% 单个块体长20*20*20
dx = (Xsrange(2) - Xsrange(1))/nsx;
dy = (Ysrange(2) - Ysrange(1))/nsy;
dz = (Zsrange(2) - Zsrange(1))/nbz;

%*********** underground modeling ***********%


%*********** Modeling ***********%

figure
set(gcf,'outerposition',get(0,'screensize'));
set(gcf,'color','w');

% 可视化模型
subplot(1,2,1)
for i1 = 1:nsx
    for i2 = 1:nsy
        for i3 = 1:nbz
            %边长，起始点（左上角），透明度，颜色             
            plotcube([dx dy dz],[position_nsx(i1) position_nsy(i2) position_nbz(i3)],0,[0 0 0])
            
        end
    end
end
set(gca,'zdir','reverse');
axis equal

%导入模型
input = load('test1.dat');
[modeling_m,modeling_n] = size(input);

for i = 1 : modeling_m
    
    plotcube([dx dy dz],[position_nsx(input(i,1)) position_nsy(input(i,2)) position_nbz(input(i,3))],0.5,[1 0 0]);
    
end

%*********** Modeling ***********%



% *********** 核矩阵构建 ***********%

G = zeros(nx * ny, nsx * nsy * nbz); % 核矩阵（观测点数x立方体数）

UGC = 6.67408 * 10 ^ -11; % 万有引力常数

for i1 = 1:nx
    for i2 = 1:ny
        
        x = Xobserved(i1);
        y = Yobserved(i2);
        z = 0;%观测点纵坐标
        
        % 套用公式计算G矩阵
        for j1 = 1:nsx
            for j2 = 1:nsy
                for j3 = 1:nbz
                    
                    x1 = position_nsx(j1);
                    x2 = position_nsx(j1 + 1);
                    
                    y1 = position_nsy(j2);
                    y2 = position_nsy(j2 + 1);
                    
                    z1 = position_nbz(j3);
                    z2 = position_nbz(j3 + 1);
                    
                    a1 = x - x1;
                    a2 = x - x2;
                    
                    b1 = y - y1;
                    b2 = y - y2;
                    
                    c1 = z - z1;
                    c2 = z - z2;
                    
                    r_111 = sqrt(a1 ^ 2 + b1 ^ 2 + c1 ^ 2);
                    r_112 = sqrt(a1 ^ 2 + b1 ^ 2 + c2 ^ 2);
                    r_121 = sqrt(a1 ^ 2 + b2 ^ 2 + c1 ^ 2);
                    r_211 = sqrt(a2 ^ 2 + b1 ^ 2 + c1 ^ 2);
                    r_122 = sqrt(a1 ^ 2 + b2 ^ 2 + c2 ^ 2);
                    r_212 = sqrt(a2 ^ 2 + b1 ^ 2 + c2 ^ 2);
                    r_221 = sqrt(a2 ^ 2 + b2 ^ 2 + c1 ^ 2);
                    r_222 = sqrt(a2 ^ 2 + b2 ^ 2 + c2 ^ 2);
                    
                    term_111 = -1 * (a1 * log(b1 + r_111) + b1 * log(a1 + r_111) - c1 * atan((a1 * b1)/(c1 * r_111)));
                    term_112 =  1 * (a1 * log(b1 + r_112) + b1 * log(a1 + r_112) - c2 * atan((a1 * b1)/(c2 * r_112)));
                    term_121 =  1 * (a1 * log(b2 + r_121) + b2 * log(a1 + r_121) - c1 * atan((a1 * b2)/(c1 * r_121)));
                    term_211 =  1 * (a2 * log(b1 + r_211) + b1 * log(a2 + r_211) - c1 * atan((a2 * b1)/(c1 * r_211)));
                    term_122 = -1 * (a1 * log(b2 + r_122) + b2 * log(a1 + r_122) - c2 * atan((a1 * b2)/(c2 * r_122)));
                    term_212 = -1 * (a2 * log(b1 + r_212) + b1 * log(a2 + r_212) - c2 * atan((a2 * b1)/(c2 * r_212)));
                    term_221 = -1 * (a2 * log(b2 + r_221) + b2 * log(a2 + r_221) - c1 * atan((a2 * b2)/(c1 * r_221)));
                    term_222 =  1 * (a2 * log(b2 + r_222) + b2 * log(a2 + r_222) - c2 * atan((a2 * b2)/(c2 * r_222)));
                    
                    
                    index1 = i1 + nx * (i2 - 1);
                    index2 = j1 + nsx * (j2 - 1) + nsx * nsy * (j3 - 1);
                    
                    G(index1,index2) = - UGC * (term_111 + term_112 + term_121 + term_211 + term_122 + term_212 + term_221 + term_222) * (10 ^ 5);
                    
                end
            end
        end
        
    end
    
end
%*********** 核矩阵构建 ***********%

%*********** 重力正演 ***********%

% 初始化每个小块的剩余密度值
m = zeros(nsx * nsy * nbz,1);

for i = 1:modeling_m
    % 代入模型位置的剩余密度值单位（kg/m^3)
    m(input(i,1) + nsx * (input(i,2) - 1) + nsx * nsy * (input(i,3) - 1)) = input(i,4) * 1000;
    
end
% 计算重力异常值
d = G * m;

% 可视化异常值
subplot(1,2,2)
% x = repelem(Xobserved,20);
% y = reshape(reshape(repelem(Yobserved,30),30,20)',600,1);
% plot3(x,y,d)
data = reshape(d,nx,ny);
[x,y]=meshgrid(reshape(Xobserved, nx, 1),reshape(Yobserved, ny, 1));
data = data';
surf(x,y,data);

% grd_write(data,Xobserved(1),Xobserved(end),Yobserved(1),Yobserved(end),'Forward.grd')
%*********** 重力正演 ***********%
save d