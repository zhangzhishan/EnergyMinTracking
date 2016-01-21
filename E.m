function [fx dfx EdetValue EdynValue EexcValue EappValue EperValue EregValue] = E(stateVec, stateInfo)
% the objective function E
%
% inputs:
% state vector, state info and scene info and options and detections
%
% outputs
% Energy value and its derivative vector
% and optionally all individual (not weighted) energy components
%
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.



global sceneInfo opt;

F=stateInfo.F; N=stateInfo.N;
targetsExist=stateInfo.targetsExist;
tiToInd=stateInfo.tiToInd;
% stateVec=stateInfo.stateVec;

% if no targets present, E=0 and return
if ~N
    fx=0;    dfx=0;
    EdetValue=0; EdynValue =0;  EexcValue=0;  EappValue=0;   EperValue=0; EregValue=0;
    return;
end


targetSize=sceneInfo.targetSize;
areaLimits=sceneInfo.trackingArea;

% params=getOptimParameters;
% global params;
% global gridStep itToInd Xd Yd Sd;
% global areaLimits;
% [X,Y]=vectorToMatrices(stateVec,stateInfo);
[X, Y]=vectorToMatrices_mex(stateVec,stateInfo.tiToInd,stateInfo.F,stateInfo.N);
% global Xgt Ygt;

% detections
global detMatrices;



% %%%%%%%%%%%%%%
% % Detections %
% %%%%%%%%%%%%%%
EdetValue=0;
dEdet=zeros(length(stateVec),1);
% EdetValue=Edet(x);
% if params.alpha>0
%     if params.det3d
        if opt.mex
            % vis needed for Eapp!!!
            if nargout>1            
                [EdetValue dEdet visv vis visx visy ddvix ddviy]= ...
                    Edet_mex(X,Y,detMatrices.Xd,detMatrices.Yd,detMatrices.Sd, ...
                    sceneInfo.targetSize,opt.lambda,stateInfo.targetsExist,length(stateVec),opt.occ);
            else
                EdetValue=Edet_mex(X,Y,detMatrices.Xd,detMatrices.Yd,detMatrices.Sd, ...
                    sceneInfo.targetSize,opt.lambda,stateInfo.targetsExist,length(stateVec),opt.occ);
            end
        else
            if nargout>1, %[EdetValue dEdet ds VIS]=Edet(x);                
                [EdetValue dEdet]=Edet(stateVec,stateInfo);
            else EdetValue=Edet(stateVec,stateInfo);
            end
        end  


%     else
%         if nargout>1, %[EdetValue dEdet ds VIS]=Edet(x);
%             [EdetValue dEdet visv visx visy ddvix ddviy]=Edet2D(x);
%         else EdetValue=Edet2D(x);
%         end
%     end
% end
% [EdetValue dEdet visv visx visy ddvix ddviy ds]=Edet(x);
% 
% % pause
% stateInfo.X=X; stateInfo.Y=Y;
% stateInfo.Xgp=stateInfo.X; stateInfo.Ygp=stateInfo.Y;
% [stateInfo.Xi stateInfo.Yi]=projectToImage(stateInfo.X,stateInfo.Y,sceneInfo);
% a=getBBoxesFromPrior(stateInfo);
% 
% %%%%%%%%%%%%%%
% % appearance %
% %%%%%%%%%%%%%%
EappValue = 0; dEapp=zeros(length(stateVec),1);
% if params.alpha>0 && doeapp
%     if nargout>1, [Eappearance dEappearance]=Eapp(x, ddvix, ddviy);
%     else
%         Eappearance=Eapp(x);
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edyn - constant velocity %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EdynValue=0; dEdyn=zeros(length(stateVec),1);
if opt.weightEdyn>0
    if opt.mex
        [EdynValue dEdyn]=Edyn_mex(X,Y,targetSize,stateInfo.targetsExist,length(stateVec));        
    else
        if nargout>1, [EdynValue dEdyn]=Edyn(stateVec,stateInfo);
        else EdynValue=Edyn(stateVec,stateInfo);
        end
    end
    
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Eexc - distance between objects %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EexcValue = 0; dEexc=zeros(length(stateVec),1);

% [size(X) size(itToInd)]
% itToInd
if N>1 && opt.weightEexc>0
    if opt.mex
        if nargout>1
            [EexcValue dEexc]=Eexc_mex(X,Y,targetSize,tiToInd,length(stateVec));
        else
            EexcValue=Eexc_mex(X,Y,targetSize,tiToInd,length(stateVec));
        end
    else
        if nargout>1, [EexcValue dEexc]=Eexc(stateVec,stateInfo);
        else EexcValue=Eexc(stateVec, stateInfo);
        end
    end

end
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Eper - persistent tracks %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
EperValue = 0; dEper=zeros(length(stateVec),1);

if opt.weightEper>0
    if opt.mex
        [EperValue dEper]=Eper_mex(X,Y,areaLimits,targetSize,targetsExist,length(stateVec));
    else
        if nargout>1, [EperValue dEper]=Eper(stateVec,stateInfo);
        else EperValue=Eper(stateVec, stateInfo);
        end
    end
end


%%%%%%%%%%%%%%%%%%
% regularization %
%%%%%%%%%%%%%%%%%%
Eregularization1=N;
% Eregularization1=(N-4)^2;
% Eregularization2=-sum(sqrt(diff(targetsExist,[],2)+1));
Eregularization2=sum(1./(diff(targetsExist,[],2)+1));
EregValue=Eregularization1+1*Eregularization2;

% Ndev=sum((sum(~~X,2)-sum(~~Xgt,2)).^2);

% final value is a linear combination of all terms
fx= opt.weightEdet*EdetValue + ...
    opt.weightEdyn*EdynValue + ...
    opt.weightEexc*EexcValue + ...
    opt.weightEper*EperValue + ...
    opt.weightEreg*EregValue;

% and the gradient
if nargout>1
    dfx = ...
        opt.weightEdet*dEdet + ...
        opt.weightEdyn*dEdyn + ...        
        opt.weightEexc*dEexc + ...
        opt.weightEper*dEper;

end