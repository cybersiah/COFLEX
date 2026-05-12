% test_solver.m

if ~libisloaded('nlp_solver')
    loadlibrary('nlp_solver.dll', ...
                'nlp_solver_dspace_wrapper.h');
end

wind_speed = 12.0;

rotor_speed = libpointer('doublePtr',0);
pitch_angle = libpointer('doublePtr',0);

calllib('nlp_solver', ...
        'solve_nlp_realtime', ...
        wind_speed, ...
        rotor_speed, ...
        pitch_angle);

fprintf('Rotor Speed = %.3f\n', rotor_speed.Value);
fprintf('Pitch Angle = %.3f\n', pitch_angle.Value);