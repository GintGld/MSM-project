function [w,W] = MetroW(edge)

mu      = [edge/1.5 edge/2.5];
Sigma   = [.3 .3; .3 .5]*edge;
x       = 0 : edge-1; 
[X1,X2] = meshgrid(x,x);
w       = mvnpdf([X1(:) X2(:)],mu,Sigma);
w       = log(w/min(w)*1.1);
W       = reshape(w,edge,edge);

figure(1)
colormap jet
image(0:edge-1,0:edge-1,transpose(W),'CDataMapping','scaled')
set(gca,'XDir','normal');
set(gca,'YDir','normal');
axis square
