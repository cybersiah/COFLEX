// nlp_solver_dspace_wrapper.c
#include "nlp_solver.h"
#include "nlp_solver_dspace_wrapper.h"
#include <math.h>
#include <stddef.h>

/* Persistent memory for warm-start */
static double x_prev[2] = {5.0, 0.1};
static double lam_g_prev[5] = {0};
static double lam_x_prev[2] = {0};

int solve_nlp_realtime(double wind_speed, double* rotor_speed, double* pitch_angle)
{
    if (rotor_speed == NULL || pitch_angle == NULL) return 0;

    /* NLP dimensions from generated solver:
       F:(x0[2],p[1],lbx[2],ubx[2],lbg[5],ubg[5],lam_x0[2],lam_g0[5])
        ->(x[2],f,g[5],lam_x[2],lam_g[5],lam_p[1])
    */
    enum { NX = 2, NG = 5, NP = 1 };

    /* Inputs */
    double x0[NX] = {x_prev[0], x_prev[1]};
    double p[NP] = {wind_speed};

    /* Decision-variable bounds (override at compile-time with /D if needed) */
#ifndef NLP_ROTOR_SPEED_MIN
#define NLP_ROTOR_SPEED_MIN 0.5
#endif
#ifndef NLP_ROTOR_SPEED_MAX
#define NLP_ROTOR_SPEED_MAX 15.0
#endif
#ifndef NLP_PITCH_MIN
#define NLP_PITCH_MIN -0.1
#endif
#ifndef NLP_PITCH_MAX
#define NLP_PITCH_MAX 1.57
#endif
    double lbx[NX] = {NLP_ROTOR_SPEED_MIN, NLP_PITCH_MIN};
    double ubx[NX] = {NLP_ROTOR_SPEED_MAX, NLP_PITCH_MAX};

    /* Constraint bounds in the same order as `g_constraints` in MATLAB:
       {'P','T','OOPTipDisp','FlapM','Torque'}
       Note: If you want a finite power/torque cap, define NLP_P_MAX / NLP_Q_MAX.
    */
#ifndef NLP_P_MIN
#define NLP_P_MIN 0.0
#endif
#ifndef NLP_P_MAX
#define NLP_P_MAX INFINITY
#endif
#ifndef NLP_T_MIN
#define NLP_T_MIN -INFINITY
#endif
#ifndef NLP_T_MAX
#define NLP_T_MAX 1500.0
#endif
#ifndef NLP_Q_MIN
#define NLP_Q_MIN 0.0
#endif
#ifndef NLP_Q_MAX
#define NLP_Q_MAX INFINITY
#endif
    double lbg[NG] = {NLP_P_MIN, NLP_T_MIN, -INFINITY, -INFINITY, NLP_Q_MIN};
    double ubg[NG] = {NLP_P_MAX, NLP_T_MAX,  INFINITY,  INFINITY, NLP_Q_MAX};

    /* Outputs */
    double x_sol[NX];
    double f_sol;
    double g_sol[NG];
    double lam_x_sol[NX];
    double lam_g_sol[NG];
    double lam_p_sol[NP];

    const casadi_real* arg[F_SZ_ARG] = {0};
    casadi_real* res[F_SZ_RES] = {0};
    casadi_int iw[F_SZ_IW];
    casadi_real w[F_SZ_W];

    /* Map the 8 function inputs */
    arg[0] = x0;
    arg[1] = p;
    arg[2] = lbx;
    arg[3] = ubx;
    arg[4] = lbg;
    arg[5] = ubg;
    arg[6] = lam_x_prev;
    arg[7] = lam_g_prev;

    /* Map the 6 function outputs */
    res[0] = x_sol;
    res[1] = &f_sol;
    res[2] = g_sol;
    res[3] = lam_x_sol;
    res[4] = lam_g_sol;
    res[5] = lam_p_sol;

    int mem = F_checkout();
    if (mem < 0) {
        *rotor_speed = x_prev[0];
        *pitch_angle = x_prev[1];
        return 0;
    }

    int status = F(arg, res, iw, w, mem);
    F_release(mem);

    if (status == 0) {
        x_prev[0] = x_sol[0];
        x_prev[1] = x_sol[1];
        lam_x_prev[0] = lam_x_sol[0];
        lam_x_prev[1] = lam_x_sol[1];
        for (int i = 0; i < NG; ++i) lam_g_prev[i] = lam_g_sol[i];
        *rotor_speed = x_prev[0];
        *pitch_angle = x_prev[1];
        return 1;
    }

    *rotor_speed = x_prev[0];
    *pitch_angle = x_prev[1];
    return 0;
}