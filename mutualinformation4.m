function [I p] = mutualinformation4(x,y,plotyn)
% This function calculates the mutual information for two signals using
% a kernel density estimator.
%
%  I = mutualinformation2(x,y)
%
%  I : mutual information (bits)
%  x,y : input signals
%  plotyn : plot the probability distributions? (1 = yes)
%  p : p-value for the mutual information value calculated here
%  
%
% I recommend using the Freedman-Diaconis rule for calculating the
% appropriate bin size.
%
% Joshua D Salvi, jsalvi@rockefeller.edu
%

if iscolumn(x) == 0
    x = x';
end
if iscolumn(y) == 0
    y = y';
end

% Kernel density estimate
%{
[bwx,dx,meshx,cdfx]=kde1d(x,2^10);
[bwy,dy,meshy,cdfy]=kde1d(y,2^10);
dx = abs(dx);
dx = dx./sum(sum(dx));
dxlog = log2(dx);
dxlog(dxlog==inf | dxlog==-inf)=0;
dy = abs(dy);
dy = dy./sum(sum(dy));
dylog = log2(dy);
dylog(dylog==inf | dylog==-inf)=0;
%}

% 2D kernel density estimate
%[xy]=gkde2([x y]);
%dxy = xy.pdf;
[bwxy,dxy,meshxyx,meshxyy]=kde2d([x y],2^10);
dxy=abs(dxy);
dxy = dxy./sum(sum(dxy));
dxylog = log2(dxy);
dxylog(dxylog==inf | dxylog==-inf)=0;

% Marginal probabilities
Inh1 = log2(sum(dxy,1));
Inh2 = log2(sum(dxy,2));
Inh1(Inh1==inf | Inh1==-inf)=0;
Inh2(Inh2==inf | Inh2==-inf)=0;

% Mutual information from the joint and marginal probabilities
I = sum(sum(dxy.*bsxfun(@minus,bsxfun(@minus,dxylog,Inh1),Inh2)));

% Calculate the p value
% Mutual information is equal to the G-test statistic divided by 2N where
% N is the sample size. The G-test is also roughly equal to a chi-squared
% distribution. 
% http://en.wikipedia.org/wiki/Mutual_information
% http://www.biostathandbook.com/chigof.html#chivsg
df = (length(meshxyx)-1)*(length(meshxyy)-1);
Gstat = I*2*length(meshxyx)*length(meshxyy);
p = gammainc(Gstat/2,df/2,'upper');     % p-value

if plotyn == 1
    figure;
    imagesc(meshx(1,:),meshy(:,1),dxy); title('Joint Probability');
    xlabel('Y');ylabel('X');colorbar
    
    figure;
    subplot(1,2,1);plot(meshx,sum(dx,2)); title('Marginal Probability (Y)');
    subplot(1,2,2);plot(meshy,sum(dy,2)); title('Marginal Probability (X)');
end

end
