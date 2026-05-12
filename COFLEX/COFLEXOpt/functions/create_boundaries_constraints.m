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