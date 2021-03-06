function [I p] = mutualinformation2(x,y,plotyn)
% This function calculates the mutual information for two signals using
% a 2D histogram.
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

% Freedman-Diaconis rule to calculate bin size
bwx = 2*iqr(x)/length(x)^(1/3);
nbx = ceil((max(x) - min(x))/bwx);
bwy = 2*iqr(y)/length(y)^(1/3);
nby = ceil((max(y) - min(y))/bwy);

% 2D histogram
[nh,co] = hist3([x y],[nbx nby]);
nh = nh./sum(sum(nh));
nhlog = log2(nh);
nhlog(nhlog==inf | nhlog==-inf)=0;

% Marginal probabilities
Inh1 = log2(sum(nh,1));
Inh2 = log2(sum(nh,2));
Inh1(Inh1==inf | Inh1==-inf)=0;
Inh2(Inh2==inf | Inh2==-inf)=0;

% Mutual information from the joint and marginal probabilities
I = sum(sum(nh.*bsxfun(@minus,bsxfun(@minus,nhlog,Inh1),Inh2)));

% Calculate the p value
% Mutual information is equal to the G-test statistic divided by 2N where
% N is the sample size. The G-test is also roughly equal to a chi-squared
% distribution. 
% http://en.wikipedia.org/wiki/Mutual_information
% http://www.biostathandbook.com/chigof.html#chivsg
df = (nbx-1)*(nby-1);
Gstat = I*2*nbx*nby;
p = gammainc(Gstat/2,df/2,'upper');     % p-value

if plotyn == 1
    figure;
    imagesc(co{2},co{1},nh); title('Joint Probability');
    xlabel('Y');ylabel('X');colorbar
    
    figure;
    subplot(1,2,1);plot(co{2},sum(nh,1)); title('Marginal Probability (Y)');
    subplot(1,2,2);plot(co{1},sum(nh,2)); title('Marginal Probability (X)');
end

end
