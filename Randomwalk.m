function Randomwalk(num)

% 设置游走的步数
N = randi([10 200],1,1);
step=1;
% 网格大小
X_max = 32;
Y_max = 32;
Z_max = 16;
% 设置起始点
Xi=randperm(X_max,1) ;
Yi=randperm(Y_max,1) ;
Zi=randperm(Z_max,1) ;
X(1:N)=0;
Y=X;
Z=Y;
X(1)=Xi;
Y(1)=Yi;
Z(1)=Zi;

figure(1)
% 开始游走并限定范围
for i=2:N
    if(rand(1,1)>=0.5)
        X(i)=X(i-1)+step;
        if(X(i)<=0)
            X(i)=1;
        end
        if(X(i)>X_max)
            X(i)=X_max;
        end
    else
        X(i)=X(i-1)-step;
        if(X(i)<=0)
            X(i)=1;
        end
        if(X(i)>X_max)
            X(i)=X_max;
        end
    end
    if(rand(1,1)<=0.5)
        Y(i)=Y(i-1)+step;
        if(Y(i)<=0)
            Y(i)=1;
        end
        if(Y(i)>Y_max)
            Y(i)=Y_max;
        end
    else
        Y(i)=Y(i-1)-step;
        if(Y(i)<=0)
            Y(i)=1;
        end
        if(Y(i)>Y_max)
            Y(i)=Y_max;
        end
    end
    if(rand(1,1)>=0.5)
        Z(i)=Z(i-1)+step;
        if(Z(i)<=0)
            Z(i)=1;
        end
        if(Z(i)>Z_max)
            Z(i)=Z_max;
        end
    else
        Z(i)=Z(i-1)-step;
         if(Z(i)<=0)
            Z(i)=1;
        end
        if(Z(i)>Z_max)
            Z(i)=Z_max;
        end
    end
    
    
         plot3(X(i),Y(i),Z(i),'.','Markersize',10,'MarkerEdgeColor','r');
         hold on
         line([X(i-1) X(i)], [Y(i-1) Y(i)],[Z(i-1) Z(i)],'linewidth',1);
         axis([ 0 X_max 0 Y_max 0 Z_max]);
         view([30 30]);
         grid on
         h=gca; 
         get(h,'fontSize') 
         set(h,'fontSize',12)
         xlabel('X','fontSize',12);
         ylabel('Y','fontSize',12);
         zlabel('Z','fontSize',12);
         title('3D Random Walk: Run 1','fontsize',14);
         fh = figure(1);
         set(fh, 'color', 'white'); 
         F=getframe;
         
end

movie(F);
% 合成model数据
rho = ones(N,1);
a = [X' Y' Z' rho];


file=['d:/Matlab/Data/', 'test', num2str(num), '.dat'];
fid=fopen(file,'wt');
[m,n]=size(a);
 for i=1:1:m
    for j=1:1:n
       if j==n
         fprintf(fid,'%g\n',a(i,j));
      else
        fprintf(fid,'%g\t',a(i,j));
       end
    end
end
fclose(fid);
      