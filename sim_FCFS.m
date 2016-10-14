% Simulation
% The FCFS scheme

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

% flow packet arrival time in terms of time slot
f_arr = ceil(f_arr_time/t_slot);
%%

% 2D array
fcfs_queue = zeros(2,temp_len);  %% queue initialization
fcfs_queue_len = 0;

fcfs_flag = 0;   %% transmission flag

% packets received
fcfs_rev_pkt = zeros(1,K);

% Deficit RR pointer
RR_pointer = 1;

% start discrete time random event simulation
t = 1;

while t<=T
    
    for j=1:K
        % event: flow packet arrives
        temp = f_arr(j,find(f_arr(j,:)>0));        
        f_arr_pkt = (temp>=(t-1)).*(temp<t);
        
        % insert into queue
        if sum(f_arr_pkt)==1
            fcfs_queue(1,fcfs_queue_len+1) = j;
            
            temp_i = find(f_arr_pkt==1);
            fcfs_queue(2,fcfs_queue_len+1) = f_pkt_size(j,temp_i);
            
            fcfs_queue_len = fcfs_queue_len + 1;
        end
        
    end    
    
    % event: starts transmissions
    if (fcfs_queue_len>0)&&(fcfs_flag==0)
        
        fcfs_flag = 1;
        
        trans_time = ceil((fcfs_queue(2,1)/C)/t_slot);
        
        fcfs_start_time = t;
        
    end
    
    % event: finishes transmission
    if (fcfs_flag>0)&&(t-fcfs_start_time+1==trans_time)
        
        % received packets
        temp_q = fcfs_queue(1,1);
        
        fcfs_rev_pkt(temp_q) = fcfs_rev_pkt(temp_q) + fcfs_queue(2,1);
        fcfs_rev_pkt(temp_q)
        % delete the arrival time of the transmitted packet
        temp_p = fcfs_queue(1,[2:end]);
        fcfs_queue(1,[1:end-1]) = temp_p;
        
        temp_j = fcfs_queue(2,[2:end]);
        fcfs_queue(2,[1:end-1]) = temp_j;
        
        fcfs_queue_len = fcfs_queue_len-1;
        
        fcfs_flag = 0;
        fcfs_start_time = 0;
        
    end
    
    t = t+1;
end

% throughput
S = fcfs_rev_pkt/Ts;
out=[[1:K],S];
save fcfs_out.mat out
figure(1)
plot([1:K],S);

