function NosePoke_Invest()
% Learning to invest time


global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    %general
    TaskParameters.GUI.Ports_M = '4';
    TaskParameters.GUI.BackPorts_LMR = '123';
    
    TaskParameters.GUI.FI = 0.5; % (s)
    TaskParameters.GUI.PreITI=1.5;
    TaskParameters.GUI.VI = false;
    TaskParameters.GUI.DrinkingTime=0.3;
    TaskParameters.GUI.DrinkingGrace=0.05;
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUIPanels.General = {'Ports_M','BackPorts_LMR', 'FI','PreITI', 'VI', 'DrinkingTime'...
        'DrinkingGrace','ChoiceDeadline'};
    
    %"stimulus"
    TaskParameters.GUI.MinSampleTime = 0.01;
    TaskParameters.GUI.EarlyWithdrawalTimeOut = 3;
    TaskParameters.GUI.EarlyWithdrawalNoise = false;
    TaskParameters.GUIMeta.EarlyWithdrawalNoise.Style='checkbox';
    TaskParameters.GUI.GracePeriod = 0.3;
    TaskParameters.GUIPanels.Sampling = {'MinSampleTime','EarlyWithdrawalTimeOut','EarlyWithdrawalNoise','GracePeriod'};
    
    %Reward
    TaskParameters.GUI.rewardAmountL = 15;
    TaskParameters.GUI.rewardAmountC = 30;
    TaskParameters.GUI.rewardAmountR = 50;
    
    TaskParameters.GUIMeta.RewardVar.Style = 'checkbox';
    TaskParameters.GUI.RewardVar = false;
    TaskParameters.GUI.rewardVarL = 0;
    TaskParameters.GUI.rewardVarC = 0;
    TaskParameters.GUI.rewardVarR = 0;
    
    TaskParameters.GUIMeta.CenterReward.Style = 'checkbox';
    TaskParameters.GUI.CenterReward=true;
    TaskParameters.GUI.CenterRewardAmount=10;
    
    TaskParameters.GUIPanels.Reward = {'rewardAmountL','rewardAmountC','rewardAmountR',...
        'RewardVar', 'rewardVarL', 'rewardVarC','rewardVarR',...
        'CenterReward','CenterRewardAmount'};
        
    %Feedback and Reward Delay
    TaskParameters.GUI.FeedbackDelay1=0.1;
    TaskParameters.GUI.FeedbackDelay2=2;
    TaskParameters.GUI.FeedbackDelay3=5;
    TaskParameters.GUIMeta.FeedbackDelayExp.Style = 'checkbox';
    TaskParameters.GUI.FeedbackDelayExp = false;
    TaskParameters.GUI.PreSignalDelay=0.1;
    
    TaskParameters.GUI.RewardDelay = 0;
    TaskParameters.GUIMeta.RewardDelayExp.Style = 'checkbox';
    TaskParameters.GUI.RewardDelayExp = false;

    
    TaskParameters.GUIPanels.RewardDelay = {'FeedbackDelay1','FeedbackDelay2','FeedbackDelay3','FeedbackDelayExp',...
        'PreSignalDelay','RewardDelay','RewardDelayExp'};
  

        
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    TaskParameters.Figures.OutcomePlot.Position = [200, 200, 1000, 400];
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors and first values
BpodSystem.Data.Custom.SampleTime(1) = TaskParameters.GUI.MinSampleTime;
BpodSystem.Data.Custom.InvestmentTime(1,:) = [TaskParameters.GUI.FeedbackDelay1,TaskParameters.GUI.FeedbackDelay2...,
    TaskParameters.GUI.FeedbackDelay3];
BpodSystem.Data.Custom.ChoiceLMR(1,:) = [NaN,NaN,NaN];
BpodSystem.Data.Custom.EarlyWithdrawal(1) = false;

BpodSystem.Data.Custom.Rewarded(1) = NaN;
BpodSystem.Data.Custom.RewardMagnitude(1,:) = [TaskParameters.GUI.rewardAmountL,TaskParameters.GUI.rewardAmountC...,
    TaskParameters.GUI.rewardAmountR];
BpodSystem.Data.Custom.TotalReward = 0;


BpodSystem.Data.Custom.GracePeriod(1) = TaskParameters.GUI.GracePeriod;
BpodSystem.Data.Custom.RewardDelay = TaskParameters.GUI.RewardDelay;
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);
%server data
[~,BpodSystem.Data.Custom.Rig] = system('hostname');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));
BpodSystem.Data.Custom.PsychtoolboxStartup=false;

%% Configuring PulsePal
load PulsePalParamStimulus.mat
load PulsePalParamFeedback.mat
BpodSystem.Data.Custom.PulsePalParamStimulus=PulsePalParamStimulus;
BpodSystem.Data.Custom.PulsePalParamFeedback=PulsePalParamFeedback;
clear PulsePalParamFeedback PulsePalParamStimulus

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', TaskParameters.Figures.OutcomePlot.Position,'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleOutcome = axes('Position',    [  .055            .15 .91 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleRS = axes('Position',  [1*.05           .6  .1  .3], 'Visible', 'on');
BpodSystem.GUIHandles.OutcomePlot.HandleTrialRate = axes('Position',    [1.5*.05 + 2*.08   .6  .1  .3], 'Visible', 'on');
BpodSystem.GUIHandles.OutcomePlot.HandleST = axes('Position',           [2.5*.05 + 4*.08   .6  .1  .3], 'Visible', 'on');
BpodSystem.GUIHandles.OutcomePlot.HandleMT = axes('Position',           [3*.05 + 6*.08   .6  .1  .3], 'Visible', 'on');
BpodSystem.GUIHandles.OutcomePlot.HandleTV = axes('Position',           [7*.05 + 6*.08   .6  .1  .3], 'Visible', 'on');

NosePoke_Invest_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'init');

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix(iTrial);
    SendStateMatrix(sma);
    
    %% Run Trial
    RawEvents = RunStateMatrix;
    
    %% Bpod save
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    %% update fields
    updateCustomDataFields(iTrial)
    
    %% update figures
    NosePoke_Invest_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'update',iTrial);


    iTrial = iTrial + 1;    
end

end

function sma = stateMatrix(iTrial)
global BpodSystem
global TaskParameters
%% Define ports
CenterPort = TaskParameters.GUI.Ports_M;
CenterPortIn = strcat('Port',num2str(CenterPort),'In');
CenterPortOut = strcat('Port',num2str(CenterPort),'Out');


bLeftPort = floor(mod(TaskParameters.GUI.BackPorts_LMR/100,10));
bCenterPort = floor(mod(TaskParameters.GUI.BackPorts_LMR/10,10));
bRightPort = mod(TaskParameters.GUI.BackPorts_LMR,10);

bLeftPortout = strcat('Port',num2str(bLeftPort),'Out');
bCenterPortout = strcat('Port',num2str(bCenterPort),'Out');
bRightPortout = strcat('Port',num2str(bRightPort),'Out');

bLeftPortIn = strcat('Port',num2str(bLeftPort),'In');
bCenterPortIn = strcat('Port',num2str(bCenterPort),'In');
bRightPortIn = strcat('Port', num2str(bRightPort),'In');

bLeftValve = 2^(bLeftPort-1);
bCenterValve = 2^(bCenterPort-1);
bRightValve = 2^(bRightPort-1);
CenterValve = 2^(CenterPort-1);




%%


bLeftValveTime  = GetValveTimes(BpodSystem.Data.Custom.RewardMagnitude(iTrial,1), bLeftPort);
bCenterValveTime  = GetValveTimes(BpodSystem.Data.Custom.RewardMagnitude(iTrial,2), bCenterPort);
bRightValveTime  = GetValveTimes(BpodSystem.Data.Custom.RewardMagnitude(iTrial,3), bRightPort);

if TaskParameters.GUI.CenterReward
    CenterValveTime  = GetValveTimes(TaskParameters.GUI.CenterRewardAmount, CenterPort);
    
end



if TaskParameters.GUI.EarlyWithdrawalNoise
    PunishSoundAction=11;
else
    PunishSoundAction=0;
end




LowState='left_on';
LowAction=bLeftPortIn;
LowLight=strcat('PWM',num2str(bLeftPort));
LowBeep={'SoftCode',13};
    

MedState='center_on';
MedAction=bCenterPortIn;
MedLight=strcat('PWM',num2str(bCenterPort));
MedBeep={'SoftCode',14};

HiState='right_on';
HiAction=bRightPortIn;
HiLight=strcat('PWM',num2str(bRightPort));
HiBeep={'SoftCode',15};

    
%disp('To change which ports are low/med/high, change the order in BackPorts_LMR')

if TaskParameters.GUI.RewardDelayExp
    BpodSystem.Data.RewardDelay(iTrial)=exprnd(TaskParameters.GUI.RewardDelay);
else
    BpodSystem.Data.RewardDelay(iTrial)=TaskParameters.GUI.RewardDelay;
    
end


sma = NewStateMatrix();
sma = SetGlobalTimer(sma,1,BpodSystem.Data.Custom.InvestmentTime(iTrial,1));
sma = SetGlobalTimer(sma,2,BpodSystem.Data.Custom.InvestmentTime(iTrial,2));
sma = SetGlobalTimer(sma,3,BpodSystem.Data.Custom.InvestmentTime(iTrial,3));


sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'PreITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'PreITI',...
    'Timer', TaskParameters.GUI.PreITI,...
    'StateChangeConditions', {'Tup', 'wait_Cin'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'wait_Cin',...
    'Timer', 0,...
    'StateChangeConditions', {CenterPortIn, 'StartSampling'},...
    'OutputActions', {strcat('PWM',num2str(CenterPort)),255});

if TaskParameters.GUI.CenterReward
    
sma = AddState(sma, 'Name', 'StartSampling',...
    'Timer', CenterValveTime,...
    'StateChangeConditions', {'Tup', 'TriggerLow'},...
    'OutputActions', {'ValveState', CenterValve});

else
    
sma = AddState(sma, 'Name', 'StartSampling',...
    'Timer', TaskParameters.GUI.MinSampleTime,...
    'StateChangeConditions', {CenterPortOut, 'EarlyWithdrawal','Tup', 'TriggerLow'},...
    'OutputActions', {});
end

sma = AddState(sma, 'Name', 'TriggerLow',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','Sampling'},...
    'OutputActions',{'GlobalTimerTrig',1});

sma = AddState(sma, 'Name', 'Sampling',...
    'Timer', BpodSystem.Data.Custom.InvestmentTime(iTrial,1),...
    'StateChangeConditions', {CenterPortOut, 'GracePeriod',...
    'GlobalTimer1_End','TriggerMed',...
    'Tup','TriggerMed'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'GracePeriod',...
    'Timer', TaskParameters.GUI.GracePeriod,...
    'StateChangeConditions', {CenterPortIn, 'Sampling','Tup','EarlyWithdrawal',...
    'GlobalTimer1_End','EarlyWithdrawal'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'TriggerMed',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','StillSampling'},...
    'OutputActions',{'GlobalTimerTrig',2});

sma = AddState(sma, 'Name', 'StillSampling',...
    'Timer', BpodSystem.Data.Custom.InvestmentTime(iTrial,2),...
    'StateChangeConditions', {CenterPortOut, 'GracePeriod2'...
    'GlobalTimer2_End','TriggerHi',...
    'Tup', 'TriggerHi'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'GracePeriod2',...
    'Timer', TaskParameters.GUI.GracePeriod,...
    'StateChangeConditions', {CenterPortIn, 'StillSampling',...
    'GlobalTimer2_End','LowInvest',...
    'Tup','LowInvest'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'TriggerHi',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','StillStillSampling'},...
    'OutputActions',{'GlobalTimerTrig',3});

sma = AddState(sma, 'Name', 'StillStillSampling',...
    'Timer', BpodSystem.Data.Custom.InvestmentTime(iTrial,3),...
    'StateChangeConditions', {CenterPortOut, 'GracePeriod3',...
    'GlobalTimer3_End','StillStillStillSampling'...
    'Tup', 'StillStillStillSampling'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'GracePeriod3',...
    'Timer', TaskParameters.GUI.GracePeriod,...
    'StateChangeConditions', {CenterPortIn, 'StillStillSampling',...
    'Tup','MedInvest',...
    'GlobalTimer3_End','MedInvest'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'StillStillStillSampling',...
    'Timer', 0,...
    'StateChangeConditions', {CenterPortOut, 'HiInvest'},...
    'OutputActions', {});

%%

sma = AddState(sma, 'Name', 'LowInvest',...
    'Timer',TaskParameters.GUI.PreSignalDelay,...
    'StateChangeConditions', {'Tup','LowInvest2'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'LowInvest2',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {LowAction,LowState,'Tup','EarlyWithdrawal'},...
    'OutputActions',[{LowLight,255}, LowBeep]);

sma = AddState(sma, 'Name', 'MedInvest',...
    'Timer',TaskParameters.GUI.PreSignalDelay,...
    'StateChangeConditions', {'Tup','MedInvest2'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'MedInvest2',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {MedAction,MedState,'Tup','EarlyWithdrawal'},...
    'OutputActions',[{MedLight,255}, MedBeep]);

sma = AddState(sma, 'Name', 'HiInvest',...
    'Timer',TaskParameters.GUI.PreSignalDelay,...
    'StateChangeConditions', {'Tup','HiInvest2'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'HiInvest2',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {HiAction,HiState,'Tup','EarlyWithdrawal'},...
    'OutputActions',[{HiLight,255}, HiBeep]);



sma = AddState(sma, 'Name', 'left_on',...
    'Timer',BpodSystem.Data.RewardDelay(iTrial),...
    'StateChangeConditions', {'Tup','bLeftPort_Reward'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'center_on',...
    'Timer',BpodSystem.Data.RewardDelay(iTrial),...
    'StateChangeConditions', {'Tup','bCenterPort_Reward'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'right_on',...
    'Timer',BpodSystem.Data.RewardDelay(iTrial),...
    'StateChangeConditions', {'Tup','bRightPort_Reward'},...
    'OutputActions',{});

%% Reward States

sma = AddState(sma, 'Name', 'bLeftPort_Reward',...
    'Timer',bLeftValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions',{'ValveState', bLeftValve});
sma = AddState(sma, 'Name', 'bCenterPort_Reward',...
    'Timer',bCenterValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions',{'ValveState', bCenterValve});
sma = AddState(sma, 'Name', 'bRightPort_Reward',...
    'Timer',bRightValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions',{'ValveState', bRightValve});

%% EndTrial States

sma = AddState(sma, 'Name', 'EarlyWithdrawal',...
    'Timer', TaskParameters.GUI.EarlyWithdrawalTimeOut,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'SoftCode',PunishSoundAction});
if TaskParameters.GUI.VI
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',exprnd(TaskParameters.GUI.FI),...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
else
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',TaskParameters.GUI.FI,...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
end

end

function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters
BpodSystem.Data.TrialTypes(iTrial)=1;
%% OutcomeRecord
statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});
BpodSystem.Data.Custom.ST(iTrial) = NaN;
BpodSystem.Data.Custom.MT(iTrial) = NaN;
BpodSystem.Data.Custom.DT(iTrial) = NaN;
BpodSystem.Data.Custom.GracePeriod(1:50,iTrial) = NaN(50,1);
if any(contains(statesThisTrial,'Invest'))
    
    if any(contains(statesThisTrial,'HiInvest'))
        BpodSystem.Data.Custom.ST(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.HiInvest(1,1) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.StartSampling(1,end);
        BpodSystem.Data.Custom.MT(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.HiInvest(1,1) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.StillStillStillSampling(1,end);
        
       

    elseif any(contains(statesThisTrial,'MedInvest'))
        BpodSystem.Data.Custom.ST(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.MedInvest(1,1) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.StartSampling(1,end);
        BpodSystem.Data.Custom.MT(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.MedInvest(1,1) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.GracePeriod3(1,1);


    elseif any(contains(statesThisTrial,'LowInvest'))
        BpodSystem.Data.Custom.ST(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.LowInvest(1,1) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.StartSampling(1,end);
        BpodSystem.Data.Custom.MT(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.MedInvest(1,1) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.GracePeriod2(1,1);

    end
    
end


if any(contains(statesThisTrial,'left_on'))
    BpodSystem.Data.Custom.ChoiceLMR(iTrial,:) = [1, 0, 0];
    BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) = false;
elseif  any(contains(statesThisTrial,'center_on'))
    BpodSystem.Data.Custom.ChoiceLMR(iTrial,:) = [0, 1, 0];
    BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) = false;
elseif  any(contains(statesThisTrial,'right_on'))
    BpodSystem.Data.Custom.ChoiceLMR(iTrial,:) = [0, 0, 1];
    BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) = false;
elseif any(contains(statesThisTrial,'EarlyWithdrawal'))
    BpodSystem.Data.Custom.ChoiceLMR(iTrial,:) = [0, 0, 0];
    BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) = true;
end



if any(contains(statesThisTrial,'bLeftPort_Reward'))
    BpodSystem.Data.Custom.Rewarded(iTrial) = true;

elseif any(contains(statesThisTrial,'bCenterPort_Reward'))
    BpodSystem.Data.Custom.Rewarded(iTrial) = true;
    
elseif any(contains(statesThisTrial,'bRightPort_Reward'))
    BpodSystem.Data.Custom.Rewarded(iTrial) = true;
else
    BpodSystem.Data.Custom.Rewarded(iTrial) = false;
end


%% initialize next trial values
BpodSystem.Data.Custom.Rewarded(iTrial+1) = false;

if TaskParameters.GUI.RewardVar
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,:) = [normrnd(TaskParameters.GUI.rewardAmountL, TaskParameters.GUI.rewardVarL),...
        normrnd(TaskParameters.GUI.rewardAmountC, TaskParameters.GUI.rewardVarC),...
   normrnd(TaskParameters.GUI.rewardAmountR, TaskParameters.GUI.rewardVarR)];
else
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,:) = [TaskParameters.GUI.rewardAmountL,TaskParameters.GUI.rewardAmountC...,
        TaskParameters.GUI.rewardAmountR];
end

BpodSystem.Data.Custom.SampleTime(iTrial+1) = TaskParameters.GUI.MinSampleTime;

if TaskParameters.GUI.FeedbackDelayExp
    BpodSystem.Data.Custom.InvestmentTime(iTrial+1,:) = [exprnd(TaskParameters.GUI.FeedbackDelay1),exprnd(TaskParameters.GUI.FeedbackDelay2)...,
        exprnd(TaskParameters.GUI.FeedbackDelay3)];
else
    BpodSystem.Data.Custom.InvestmentTime(iTrial+1,:) = [TaskParameters.GUI.FeedbackDelay1,TaskParameters.GUI.FeedbackDelay2...,
        TaskParameters.GUI.FeedbackDelay3];
end

BpodSystem.Data.Custom.ChoiceLMR(iTrial+1,:) = [NaN,NaN,NaN];


BpodSystem.Data.Custom.EarlyWithdrawal(iTrial+1) = false;
BpodSystem.Data.Custom.ST(iTrial+1) = NaN;
BpodSystem.Data.Custom.MT(iTrial+1) = NaN;
BpodSystem.Data.Custom.GracePeriod(1:50,iTrial+1) = NaN(50,1);

BpodSystem.Data.Custom.RewardDelay(iTrial+1) = NaN;
BpodSystem.Data.Custom.Rewarded(iTrial+1) = NaN;


%send bpod status to server
% try
% script = 'receivebpodstatus.php';
% %create a common "outcome" vector
% outcome = BpodSystem.Data.Custom.ChoiceLeft(1:iTrial); %1=left, 0=right
% outcome(BpodSystem.Data.Custom.EarlyWithdrawal(1:iTrial))=3; %early withdrawal=3
% outcome(BpodSystem.Data.Custom.Jackpot(1:iTrial))=4;%jackpot=4
% SendTrialStatusToServer(script,BpodSystem.Data.Custom.Rig,outcome,BpodSystem.Data.Custom.Subject,BpodSystem.CurrentProtocolName);
% catch
% end

end