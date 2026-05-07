function compile_NLP_to_C_corrected(turbine, opt_weights, x_constraints, g_constraints, tsr_fix)
    % Compile NLP solver to C code for real-time dSpace deployment
    % Wind speed is a PARAMETER (changes each call, not optimized over)
    
    import casadi.*

    RotSpd   = MX.sym('RotSpd');      % Optimization variable 1
    Pitch    = MX.sym('Pitch');       % Optimization variable 2

    wndspd   = MX.sym('wndspd');      % Wind speed - INPUT parameter
    
    %initieren van solve_NLP
    Cp = turbine.Cp([RotSpd, wndspd, Pitch]);
    Ct = turbine.Ct([RotSpd, wndspd, Pitch]);
    
    CP_weight = opt_weights(1);
    CT_weight = opt_weights(3);
    CQ_weight = opt_weights(2);
    
    CP_f = Cp;
    CT_f = Ct;
    CQ_f = Cp / (RotSpd * turbine.R) * wndspd;
    
    f = CP_weight * CP_f + CT_weight * CT_f + CQ_weight * CQ_f;
    
    g = create_function_constraints(g_constraints, turbine, RotSpd, wndspd, Pitch);
    [lbg, ubg] = create_boundaries_constraints(g_constraints);
    
    % structuur
    nlp = struct;
    nlp.x = [RotSpd; Pitch];          % te optimalizeren variabele
    nlp.p = wndspd;                   
    nlp.f = f;                        s
    nlp.g = g;                        
    
    % snelheid en andere opties van het oplossen van de NLP
    options = struct;
    options.ipopt.max_iter = 500;              % Reduced for real-time
    options.ipopt.warm_start_init_point = 'yes';
    options.ipopt.print_level = 0;             % Silent in production
    options.print_time = false;
    options.verbose = false;
    
    % tolerantie
    options.ipopt.acceptable_tol = 1e-4;       % Looser tolerance for speed
    options.ipopt.acceptable_iter = 10;        % Accept solution after 10 iterations if good enough
    options.ipopt.acceptable_compl_inf_tol = 1e-4;
    
    disp('Creating NLP solver...');
    F = nlpsol('F', 'ipopt', nlp, options);
    
    % ===================== GENERATE C CODE =====================
    disp('Generating C code...');
    
    F.generate('nlp_solver', struct(...
        'main', false, ...                      % Don't create main() function
        'with_header', true, ...                % Generate header file
        'indent', true ...
    ));
    
    disp(' maak nlp_solver.c');
    disp('maak nlp_solver.h');
    
    % ===================== GENERATE FUNCTION DEFINITIONS FILE =====================
    % This file contains the external wrapper for dSpace/Simulink
    generate_dspace_wrapper();
    
end