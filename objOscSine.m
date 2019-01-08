% Synthesize single note

%classdef objSynthSineNote < matlab.System
classdef objOscSine < handle
    properties
        % Defaults
        BufferSize                                  = 256;
        SamplingRate                                = 44100;
        Attack                                      = .1;
        Release                                     = .2;
    end
    %properties (GetAccess = private)
    properties
        % Private members
        currentTime;
        durationPerBuffer;
        note                  = objNote.empty;
        attackInd
        releaseInd
        attackMaxInd
        releaseMaxInd
        attackWaveform
        releaseWaveform
    end
    
    methods
        function obj = objOscSine(varargin)
            if nargin > 0
                obj.currentTime=0;
                
                if nargin >= 5
                    obj.SamplingRate=varargin{5};
                end
                if nargin >= 4
                    obj.BufferSize=varargin{4};
                end
                if nargin >= 3
                    obj.Release=varargin{3};
                end
                if nargin >= 2
                    obj.Attack=varargin{2};
                end
                obj.note=varargin{1};
            end
            obj.durationPerBuffer=obj.BufferSize/obj.SamplingRate;
            
            obj.attackInd=1;                        %Intialize indices for cases when buffer wraps
            obj.releaseInd=1;
            
            obj.attackMaxInd=ceil(obj.Attack.*obj.SamplingRate);
            obj.releaseMaxInd=ceil(obj.Release.*obj.SamplingRate);
        
            obj.attackWaveform=linspace(0,1,obj.attackMaxInd);
            obj.releaseWaveform=linspace(1,0,obj.releaseMaxInd);
        
        end
        
    end
    
    %methods (Access = protected)
    %function audio = stepImpl(~)
    methods
        function audio = advance(obj)
            
            timeVec=(obj.currentTime+(0:(1/obj.SamplingRate):((obj.BufferSize-1)/obj.SamplingRate))).';
            noteTime=timeVec-obj.note.startTime;
            
            indVec=1:length(timeVec);
            
            if all(timeVec>(obj.note.endTime+obj.Release))                                        % After the note is over - output empty audio to indicate processing is complete
                audio=[];       
            elseif any(timeVec>=obj.note.startTime)                                  % During the note mask the time 
                mask=(timeVec >= obj.note.startTime & timeVec<(obj.note.endTime+obj.releaseMaxInd));
                mask=double(mask);
                % Insert the attack waveform
                
                if obj.attackInd>obj.attackMaxInd
                    % Leave mask as all ones
                else 
                    tmpAttackDur=(min(length(mask),obj.attackMaxInd));
                    mask(min(find(mask))+(0:(tmpAttackDur-1)))=obj.attackWaveform(obj.attackInd+(0:(tmpAttackDur-1)));    % Replace the ramp up with the attach waveform
                    obj.attackInd=obj.attackInd+tmpAttackDur;
                end
                
                if(any(timeVec>(obj.note.endTime)))
                    if all(timeVec<(obj.note.endTime+obj.Release))
                        [tmp,indRelease]=min(abs(timeVec-(obj.note.endTime)));
                        tmpReleaseDur=(min(length(mask),obj.releaseMaxInd));
                        mask(indRelease+(0:(tmpReleaseDur-1)))=obj.releaseWaveform((obj.releaseInd+(0:(tmpReleaseDur-1))));
                        obj.releaseInd=obj.releaseInd+tmpReleaseDur;
                    else
                        mask=zeros(1,obj.BufferSize).';
                    end
                    
                end
                
                audio=mask.*sin(2*pi*obj.note.frequency*timeVec);
            else                                                                    % Before the note begins output zeros
                audio = zeros(1,obj.BufferSize).';
                obj.attackInd=1;
                obj.releaseInd=1;
            end
            obj.currentTime=obj.currentTime+(obj.BufferSize/obj.SamplingRate);      % Advance the internal time
        end
    end
end




