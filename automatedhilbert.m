clear all
close all

load('/Users/joshsalvi/Documents/Lab/Lab/Data Analysis/State Spaces/20130903/20130903-cell12.mat');
%Xd=Xd(3e4:79001,:,:);
%Xd_pulse=Xd_pulse(3e4:79001,:,:);
%Xd=Xd*0.7*0.6;
%Xd_pulse=Xd_pulse*0.7*0.6;

%time.data(:,1,1) is the time vec. Don't know what the other elements of
%time are but they're not time values.

sizeXd = size(Xd);
Np = sizeXd(2);
Nt = sizeXd(3);

%Three points are duplicates at (0,0) 
Fsort = sort(F_rand);
Fgrid = Fsort(diff(Fsort) ~= 0);
Fgrid(end+1) = max(F_rand);
ksort = sort(k_rand);
kgrid = ksort(diff(ksort) ~= 0);
kgrid(end+1) = max(k_rand);

for i = 1:N_k
for j = 1:N_F

clear binPosS SG0     
    
kpt = kgrid(i);
Fpt = Fgrid(N_F-j+1);
kpt*10^6
Fpt*10^12
Nptlist = find(k_rand == kpt & F_rand == Fpt);
if isempty(Nptlist)
    break;
end
Npt = Nptlist(1);
Npulse = mod(Npt-1,Np)+1
Ntrial = ceil(Npt/Np)

figure(1);hold on;
subplot(N_F,N_k,i+(j-1)*N_k)
%plot control parameters and responses on a normalized scale
plot(time.data(:,1,1),Xc(:,Npulse,Ntrial)/max(abs(Xc(:,Npulse,Ntrial))),'k')
title(['F=',num2str(Fpt*10^12),', k=',num2str(kpt*10^6)])

hold on
%plot(time.data(:,1,1),Gain(:,Npulse,Ntrial)/max(abs(Gain(:,Npulse,Ntrial))),'g')
plot(Xd(:,Npulse,Ntrial)/max(abs(Xd(:,Npulse,Ntrial))),'r')
%plot(time.data(:,1,1),Delta(:,Npulse,Ntrial)/max(abs(Delta(:,Npulse,Ntrial))),'b')

AfterRamp = find(time.data(:,1,1) >= ramp*100);

%Use only end of data to get steady state response
AfterRamp(1) = round(0.5*length(time.data(:,1,1)));

BeforeRamp = find(time.data(:,1,1) <= time.data(end,1,1)-ramp*100);

XdR = Xd_pulse(:,Npulse,Ntrial);
timeR = linspace(0,length(XdR),length(XdR));
%XdR = Xd(AfterRamp(1):BeforeRamp(end),Npulse,Ntrial);
%timeR = time.data(AfterRamp(1):BeforeRamp(end),1,1);

%Modality of displacement histogram depends strongly upon how the data is
%detrended an upon whether the steady state has been reached.
XdRS = XdR - smooth(XdR,round(length(XdR)/5),'sgolay',1);
%The mean should be near zero
mean(XdRS);
figure(2);hold on;
subplot(N_F,N_k,i+(j-1)*N_k)

plot(timeR,XdRS,'r')
XdRSS = smooth(XdRS,Fs/2000,'sgolay',1);
hold on
plot(timeR,XdRSS,'k')
XdRS = XdRSS;
title(['F=',num2str(Fpt*10^12),', k=',num2str(kpt*10^6)])

%Bin width using the Freedman/Diaconis rule
bw = 2*iqr(XdRS)/length(XdRS)^(1/3);
Nbins = round((max(XdRS) - min(XdRS))/bw);
%Must redifine bin width such that Nbins*BinSize = max - min
BinSize = (max(XdRS) - min(XdRS))/Nbins;
[binFreq,binPos]=hist(XdRS,Nbins);
figure(3);hold on;
subplot(N_F,N_k,i+(j-1)*N_k)

bar(binPos,binFreq)
title(['F=',num2str(Fpt*10^12),', k=',num2str(kpt*10^6)])

ws = round(Nbins/6); %Must be odd   %%% ******* CHANGE WINDOW SIZE HERE ********
if mod(ws,2) == 0
    ws = ws + 1;
end
%binFreqS = smooth(binFreq,ws,'sgolay',1);
%hold on
%plot(binPos,binFreqS,'r')

%Changing the order of the polynomial changes the first derivative
%Looking for a cubic at most in the local distribution shape
[b,g] = sgolay(4,ws);   % Calculate S-G coefficients

dx = binPos(2) - binPos(1);
HalfWin  = ((ws+1)/2) -1;
SG0 = zeros(1,length((ws+1)/2:length(binFreq)-(ws+1)/2));
SG1 = zeros(1,length((ws+1)/2:length(binFreq)-(ws+1)/2));
SG2 = zeros(1,length((ws+1)/2:length(binFreq)-(ws+1)/2));
for n = (ws+1)/2:length(binFreq)-(ws+1)/2,
  SG0(n-(ws+1)/2+1) = dot(g(:,1), binFreq(n - HalfWin: n + HalfWin));
  SG1(n-(ws+1)/2+1) = dot(g(:,2), binFreq(n - HalfWin: n + HalfWin));
  SG2(n-(ws+1)/2+1) = 2*dot(g(:,3)', binFreq(n - HalfWin: n + HalfWin))';
  binPosS(n-(ws+1)/2+1) = binPos(n);
end
hold on
plot(binPosS,SG0,'g')
SG1 = SG1/dx;         % Turn differential into derivative
SG2 = SG2/dx^2;         % Turn differential into derivative
figure(4);hold on;
subplot(N_F,N_k,i+(j-1)*N_k)

plot(binPosS,SG0,'g')
hold on
plot(binPosS,SG1,'r')
plot(binPosS,SG2,'b')
line([binPosS(1) binPosS(end)],[0 0],'LineStyle','-')
title(['F=',num2str(Fpt*10^12),', k=',num2str(kpt*10^6)])

%Distribution must have positive slopes at beginning and end
binPosS(find(abs(diff(sign(SG1)))==2))
MaxNumber = (length(find(abs(diff(sign(SG1)))==2))+1)/2
text(0.8*max(binPos),0.8*max(binFreq),[num2str(MaxNumber) ' max'],'HorizontalAlignment','left')

h = 1;
if h == 1
XdRSA = hilbert(XdRS);

%Create a vector plot
DXdRSA = diff(XdRSA)./(timeR(2)-timeR(1));
XdRSAVec = XdRSA;
XdRSAVec(end) = [];

%{
figure(5);hold on;
subplot(N_F,N_k,i+(j-1)*N_k)

quiver(real(XdRSAVec),imag(XdRSAVec),real(DXdRSA),imag(DXdRSA));
axis([-20 20 -20 20])
title(['F=',num2str(Fpt*10^12),', k=',num2str(kpt*10^6)])
%}
minR = min(real(XdRSA));
maxR = max(real(XdRSA));
minI = min(imag(XdRSA));
maxI = max(imag(XdRSA));

BinSizeR = 2*iqr(real(XdRSA))/length(XdRSA)^(1/3);
NRbins = floor((maxR - minR)/BinSizeR);
BinSizeI = 2*iqr(imag(XdRSA))/length(XdRSA)^(1/3);
NIbins = floor((maxI - minI)/BinSizeI);

%NRbins = round(maxR - minR)*1;
%NIbins = round(maxI - minI)*1;
%BinSizeR = ((maxR - minR))/NRbins;
%BinSizeI = ((maxI - minI))/NIbins;

AHist = zeros(NRbins,NIbins);
Rpos = (minR+BinSizeR/2):BinSizeR:(maxR-BinSizeR/2);
Ipos = (minI+BinSizeI/2):BinSizeI:(maxI-BinSizeI/2);

for R = 1:NRbins
    for I = 1:NIbins
    AHist(R,I) = sum(real(XdRSA)<(Rpos(R)+BinSizeR/2) & real(XdRSA)>=(Rpos(R)-BinSizeR/2) & imag(XdRSA)<(Ipos(I)+BinSizeI/2) & imag(XdRSA)>=(Ipos(I)-BinSizeI/2));
    end
end
figure(6);hold on;
subplot(N_F,N_k,i+(j-1)*N_k)

surf(Rpos,Ipos,AHist','EdgeColor','none')
set(gca,'Color',[0 0 0.5]);
axis([-50 50 -50 50])
view(2);
title(['F=',num2str(Fpt*10^12),', k=',num2str(kpt*10^6)])
%colormap(flipud(jet))
shading interp


end

end
end
