
function g_function = create_function_constraints(g_constraints,turbine,RotSpd,wndspd_fix,Pitch)

%% Handling constraints
constraints = struct();

% Iterate over fields in g_constraints
fields = fieldnames(g_constraints);
for i = 1:numel(fields)
    field = fields{i};
    
    % Extract the corresponding variable from turbine
    variable = turbine.(field)([RotSpd,wndspd_fix,Pitch]);  % Assuming the field in turbine has the same name as in g_constraints
    
    % Assign to constraints structure
    constraints.(field) = variable;
end

% Initialize empty array for g
g = [];

% Iterate over fields in constraints
fields = fieldnames(constraints);
for i = 1:numel(fields)
    field = fields{i};
    
    % Extract the variable value from constraints
    variable_value = constraints.(field);
    
    % Add the variable value to g
    g = [g; variable_value];
end

g_function = g;

end

function [low_bound_g,up_bound_g] = create_boundaries_constraints(g_constraints)

% Initialize empty arrays for lower and upper bounds
lbg = [];
ubg = [];

% Iterate over fields in g_constraints
fields = fieldnames(g_constraints);

for i = 1:numel(fields)
    field = fields{i};

    % Extract lower and upper bounds from g_constraints
    lb = g_constraints.(field)(1);
    ub = g_constraints.(field)(2);
    
    % Append lower and upper bounds to lbg and ubg arrays
    lbg = [lbg; lb];
    ubg = [ubg; ub];
end

low_bound_g = lbg;
up_bound_g  = ubg;

end