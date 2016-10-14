% Simulation
% The DRR scheme

clear all
close all

% # of flows
K = 5;

% maximum packet size (bits)
Max = 4500;

% link speed (Bytes/s)
C = 1e+6/8;

% normal packet rate (packet/second)
lambda = 10;

% ill packet rate
lambda_x = 3*lambda;

% length of a time slot (unit: second)
t_slot = 1e-2;

% Simulation duration (unit: second)
Ts = 200;

% total simulation time slot
T = Ts/t_slot;
%T=T/100;
%% generate the ill-behaved traffic
jj = 1;
f_arr_time_x = 0;
f_pkt_size_x = 0;
f_px = 1/lambda_x;
tp_x = 0;

while tp_x<=Ts
    
    f_int_time_x = exprnd(f_px); %% packet inter-arrival time follows exponential distribution
    f_arr_time_x(jj) = tp_x+f_int_time_x;
    
    % packet size
    pkt = ceil(rand(1)*Max);
    f_pkt_size_x(jj) = pkt;
    
    tp_x = f_arr_time_x(jj);
    
    jj = jj+1;
end

temp_len = length(f_arr_time_x);
%%

% normal traffic initialization
f_p = 1/lambda;
tp = zeros(1,K);

% use a 2-D array to store the packet arrival time
f_arr_time = zeros(K,temp_len);
% packet size
f_pkt_size = zeros(K,temp_len);

% for every flow, store its arrival time
for j=1:K
    ii = 1;
    
    while tp(j)<=Ts
        
        f_int_time(j) = exprnd(f_p); %% packet inter-arrival time follows exponential distribution        
        f_arr_time(j,ii) = tp(j)+f_int_time(j);
        
        % packet size
        pkt = ceil(rand(1)*Max);        
        f_pkt_size(j,ii) = pkt;
        
        tp(j) = f_arr_time(j,ii);
        
        ii = ii+1;
    end
end

f_arr_time(3,:) = f_arr_time_x;
f_pkt_size(3,:) = f_pkt_size_x;


DRR_flag=0;

% flow packet arrival time in terms of time slot
f_arr = ceil(f_arr_time/t_slot);
%%

% 2D array
DRR_queue = zeros(K,2);  %% queue initialization
DRR_queue_len = 0;

% Quantum size
Q = 500;


drr_flag = 0;   %% transmission flag
DRR_start_time = 0;
trans_time = 0;

% packets received
DRR_rev_pkt = zeros(1,K);

% Deficit RR pointer
DRR_pointer = 1;

% Deficit counter
%DC_queue = zeros(1,K);


% Active queue list
Act_queue_list = zeros(1,K);

% start discrete time random event simulation
t = 1;

DC=0;
cnt=1;
temp=zeros(1,2);
arr=temp;
f=1;
while t<=T 
   for j=1:K
        % event: flow packet arrives
        temp = f_arr(j,find(f_arr(j,:)>0));        
        f_arr_pkt = (temp>=(t-1)).*(temp<t);
        
        % insert into queue
        if sum(f_arr_pkt)==1
            DRR_queue(1,DRR_queue_len+1) = j;
            
            temp_i = find(f_arr_pkt==1);
            DRR_queue(2,DRR_queue_len+1) = f_pkt_size(j,temp_i);
            
            DRR_queue_len = DRR_queue_len + 1;
        end
        
   end  
   
      
    % event: starts transmissions
    if (DRR_queue_len>0)&(DRR_flag==0)
        if (DC>=DRR_queue(2,1))
            DC=DC-DRR_queue(2,1);
            
            DRR_flag = 1;

            trans_time = ceil((DRR_queue(2,1)/C)/t_slot);

            DRR_start_time = t;
            
        else
             %updating the Deficit counter
DC=(DC+Q);
            % DRR_flag = 0;
             arr=[DRR_queue(1,1) DRR_queue(2,1)];
             %updating the DRR pointer
              DRR_queue(1,1)=rem(ceil(rand(1)*10),K+1);
%              if(f==ceil(K/2))
%                  f=ceil(K/2)+1;
%              end

             
            DRR_flag = 1;


              if(DRR_queue(1,1)==0)
                  DRR_queue(1,1)=K;
              end
            trans_time = ceil((DRR_queue(2,1)/C)/t_slot);

            DRR_start_time = t;
        end
        
        if DRR_queue(2,1)==0
                DC=0;
         end
     end
    
    
    % event: finishes transmission
    if (DRR_flag>0)&(t-DRR_start_time+1==trans_time)
        
        % received packets
        temp_q = DRR_queue(1,1);
        DRR_rev_pkt(temp_q) = DRR_rev_pkt(temp_q) + DRR_queue(2,1);
       
        % delete the arrival time of the transmitted packet
        temp_p = DRR_queue(1,[2:end]);
        DRR_queue(1,[1:end-1]) = temp_p;
        
        temp_j = DRR_queue(2,[2:end]);
        DRR_queue(2,[1:end-1]) = temp_j;
        
        DRR_queue_len = DRR_queue_len-1;
        
        DRR_flag = 0;
        DRR_start_time = 0;
    
    end
    
    t = t+1;
   
end
%DRR_rev_pkt=DRR_rev_pkt*4;
%[r,c] = max(DRR_rev_pkt);
%DRR_rev_pkt(c)=DRR_rev_pkt(c)/2.2;
S_new = DRR_rev_pkt/Ts;
load fcfs.mat
%figure(1)
%p=plot([1:K],S_new,'Color','b','Marker','x',out(1,:),out(2,:),'Color','r','Marker','x');
%p(2).Marker = 'x';

figure
plot([1:K],S_new,'b',...
    'LineWidth',2,...
    'Marker','x',...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5])
hold on;
plot(out(1,:),out(2,:),'--r',...
    'LineWidth',2,...
    'Marker','x',...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5])
legend('DRR queuing','FCFS queuing');
xlabel('Flows');
ylabel('Throughput(kbps)');
