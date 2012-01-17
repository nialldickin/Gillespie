function [ t, x ] = firstReactionMethod( stoich_matrix, propensity_fcn, tspan, x0,...
                                         rate_params, output_fcn, MAX_OUTPUT_LENGTH)
%FIRSTREACTIONMETHOD Implementation of the First-Reaction Method variant of the Gillespie algorithm
%   Based on: Gillespie, D.T. (1977) Exact Stochastic Simulation of Coupled
%   Chemical Reactions. J Phys Chem, 81:25, 2340-2361.
%
%       [t, x] = SSA.firstReactionMethod( stoich_matrix, propensity_fcn, tspan, x0 )
%       [t, x] = SSA.firstReactionMethod( stoich_matrix, propensity_fcn, tspan, x0, ...
%                                         rate_params )
%       [t, x] = SSA.firstReactionMethod( stoich_matrix, propensity_fcn, tspan, x0, ...
%                                         rate_params, output_fcn )
%
%   Author:     Nezar Abdennur
%   Created:    2012-22-12
%   Copyright:  (c) Nezar Abdennur 2012
%   Version:    1.0.0
%
%   See also SSA, SSA.DIRECTMETHOD

if ~exist('MAX_OUTPUT_LENGTH','var')
    MAX_OUTPUT_LENGTH = 1000000;
end
if ~exist('output_fcn', 'var')
    output_fcn = [];
end
if ~exist('rate_params', 'var')
    rate_params = [];
end

%% Initialize
num_rxns = size(stoich_matrix, 1);
num_species = size(stoich_matrix, 2);
T = zeros(MAX_OUTPUT_LENGTH, 1);
X = zeros(MAX_OUTPUT_LENGTH, num_species);
T(1)     = tspan(1);
X(1,:)   = x0;
rxnCount = 1;

%% MAIN LOOP
while T(rxnCount) <= tspan(2)        
    % Step 1: calculate propensities
    a  = propensity_fcn(X(rxnCount,:), rate_params);
    
    % Step 2: calculate tau_i for each reaction channel using random variates
    % tau is the smallest tau_i and mu is its index
    r = rand(1,num_rxns);
    taus = -log(r)./a;
    [tau, mu] = min(taus);

    % Update time and carry out reaction mu
    rxnCount = rxnCount + 1; 
    T(rxnCount)   = T(rxnCount-1)   + tau;
    X(rxnCount,:) = X(rxnCount-1,:) + stoich_matrix(mu,:);                
    
    if ~isempty(output_fcn)
        stop_signal = feval(output_fcn, T(rxnCount), X(rxnCount,:)');
        if stop_signal
            t = T(1:rxnCount-1);
            x = X(1:rxnCount-1,:);
            warning('SSA:TerminalEvent',...
                    'Simulation was terminated by OutputFcn.');
            return;
        end 
    end
    
    if rxnCount > MAX_OUTPUT_LENGTH
        t = T(1:rxnCount-1);
        x = X(1:rxnCount-1,:);
        warning('SSA:ExceededCapacity',...
                'Number of reaction events exceeded the number pre-allocated. Simulation terminated prematurely.');
        return;
    end
end  

% Record output
t = T(1:rxnCount-1);
x = X(1:rxnCount-1,:);
if t(end) < tspan(2)
    t(end) = tspan(2);
end    

end

