#include <complex>
#include <vector>
#include <mex.h>
#include <math.h>
#include <nlopt.hpp>
#include <cassert>

// Install NLopt first: http://ab-initio.mit.edu/wiki/index.php/NLopt

// compile using command:
//     mex FRETPhasor.cpp 'CXXFLAGS="$CXXFLAGS -std=c++11 -O3"' -I/usr/local/include -L/usr/local/lib -lnlopt

using namespace std;

float omega = 2*M_PI/12500;

struct System
{
    float sigmaQ;
    float Qdash;
    float aD[2];
    float aA[2];
    float tauD[2];
    float alphaD[2];
    float tauA = 4000;
};

class Phasor
{
public:
    complex<float> phasor;
    float I = 0;
    
    Phasor& operator+=(const Phasor& other) 
    {
        float newI = I + other.I;
        phasor = (I * phasor + other.I * other.phasor) / newI;
        I = newI;
        return *this;
    }

    Phasor& operator*=(float v) 
    {
        I *= v;
        return *this;
    }

    Phasor& operator/=(float v) 
    {
        I /= v;
        return *this;
    }
};

Phasor operator+(const Phasor& p1, const Phasor& p2) 
{
    Phasor p;
    p.I = p1.I + p2.I;
    p.phasor = (p1.I * p1.phasor + p2.I * p2.phasor) / p.I;
    return p;
}

Phasor operator*(const Phasor& p1, float v) 
{
    Phasor p = p1;
    p.I *= v;
    return p;
}

Phasor operator*(float v, const Phasor& p1) 
{
    Phasor p = p1;
    p.I *= v;
    return p;
}

Phasor operator/(const Phasor& p1, float v) 
{
    Phasor p = p1;
    p.I /= v;
    return p;
}


System s_CFP;
System s_GFP;

//vector<Phasor> measured_phasor;

complex<float> r(float tau)
{
    return tau / (1.0f-complex<float>(0,omega*tau));
}


void setup()
{
    s_CFP.sigmaQ = 0.02;
    s_CFP.Qdash = 2;
    s_CFP.aD[0] = 0.4425;
    s_CFP.aD[1] = 0.4433;
    s_CFP.aA[0] = 0.6717, 
    s_CFP.aA[1] = 0.0023;
    s_CFP.tauD[0] = 3500;
    s_CFP.tauD[1] = 960;
    s_CFP.alphaD[0] = 0.6;
    s_CFP.alphaD[1] = 0.4;
    s_CFP.tauA = 2800;
    
    s_GFP.sigmaQ = 0.044;
    s_GFP.Qdash = 0.416;
    s_GFP.aD[0] = 0.7578;
    s_GFP.aD[1] = 0.1461;
    s_GFP.aA[0] = 0.0000;
    s_GFP.aA[1] = 0.0000;
    s_GFP.tauD[0] = 2400;
    s_GFP.tauD[1] = 1000;
    s_GFP.alphaD[0] = 1;
    s_GFP.alphaD[1] = 0;
    s_GFP.tauA = 4000;
}


void FRETphasor(const System& s, float k, vector<Phasor>& phasor)
{
    float A[2], tauDA[2];
    phasor.resize(2);
    
    for(int j=0; j<2; j++)
        phasor[j].I = 0;
    
    for(int i=0; i<2; i++)
    {
        A[i] = k / (s.tauA - s.tauD[i] + k);
        tauDA[i] = s.tauD[i] / (1 + k);
        
        for(int j=0; j<2; j++)
        {
            phasor[j].I += (s.alphaD[i] * tauDA[i] * s.aD[j]);
            phasor[j].I += (s.alphaD[i] * (s.tauA - tauDA[i]) * s.aA[j]);
        }
    }

    for(int j=0; j<2; j++)
    {
        complex<float> FD1 = 0, FD2 = 0;
        complex<float> FA1 = 0, FA2 = 0;
        
        for(int i=0; i<2; i++)
        {
            complex<float> FD = s.alphaD[i] * (s.aD[j] / s.tauD[i] - A[i] * s.Qdash * s.aA[j]);
            complex<float> FA = s.alphaD[i] * (s.sigmaQ * s.aA[j] / s.tauA + A[i] * s.Qdash * s.aA[j]);

            FD1 += FD1 + FD * r(tauDA[i]);
            FD2 += FD2 + FD * tauDA[i];

            FA1 += FA * r(s.tauA);
            FA2 += FA * s.tauA;
        }
        
        phasor[j].phasor = (FD1 + FA1) / (FD2 + FA2);
    }
    
}        


void printPhasor(const Phasor& phasor)
{
    mexPrintf("   P: %f + %f i, I: %f \n", phasor.phasor.real(), phasor.phasor.imag(), phasor.I);
}


void staticFRETphasor(const System& s, float k, vector<Phasor>& phasor)
{
    phasor.resize(2);
    float F = 3.0 / 2.0 * k;
    
    int n = 20;
    
    float Emax = 1; //4.0 * F / (1.0 + 4.0 * F);
    float dE = Emax/n;
    float sum_p = 0;

    vector<Phasor> Ephasor(2);
    
    float Ethresh = F/(1+F);

    for (int i=0; i<n; i++)
    {

        
        float E = (i + 1) * dE;

        if (E >= (4.0 * F / (1.0 + 4.0 * F)))
            continue;
        
        float p = 1.0/(2.0*(1-E)*sqrt(3.0*E*F*(1-E)));
        
        float q = E/(F*(1-E));
        p = p * ((E < Ethresh) ? 
                         log(2+sqrt(3)) 
                       : log((2 + sqrt(3))/(sqrt(q)+sqrt(q-1))));
                       
        sum_p += p;
        
        float kE = E / (1-E);
        FRETphasor(s, kE, Ephasor);
        for(int i=0; i<2; i++)
            phasor[i] += p * Ephasor[i];
    }
    
    for(int i=0; i<2; i++)
        phasor[i] /= sum_p;

}

vector<Phasor> systemPhasor(float A_CFP, float A_GFP, float k_CFP, float k_GFP)
{    
    //mexPrintf("A: %f, %f, k: %f, %f\n", A_CFP, A_GFP, k_CFP, k_GFP);
    vector<Phasor> cfp, gfp;
    
    staticFRETphasor(s_CFP, k_CFP, cfp);
    staticFRETphasor(s_GFP, k_GFP, gfp);

    vector<Phasor> phasor(2);
    for(int i=0; i<2; i++)
        phasor[i] = A_CFP * cfp[i] + A_GFP * gfp[i]; 

    return phasor;
}

double objective(unsigned n, const double* x, double* grad, void* f_data)
{
    vector<Phasor>& measured_phasor = *((vector<Phasor>*)f_data);
    
    float A_CFP = exp(x[0]);
    float A_GFP = exp(x[1]);
    float k_CFP = exp(x[2]);
    float k_GFP = exp(x[3]);
        
    vector<Phasor> phasor = systemPhasor(A_CFP, A_GFP, k_CFP, k_GFP);
    
    //printPhasor(phasor[0]);
    //printPhasor(phasor[1]);
        
    float residual = 0;
    for (int i=0; i<2; i++)
    {
        complex<float> p_diff = phasor[i].phasor - measured_phasor[i].phasor;
        float I_diff = phasor[i].I - measured_phasor[i].I;
        residual += p_diff.real()*p_diff.real() + p_diff.imag()*p_diff.imag() + I_diff*I_diff;
    }
    
    //mexPrintf("Cur: %f, %f, %f, %f  -> %f\n", A_CFP, A_GFP, k_CFP, k_GFP,residual);

    if(!isfinite(residual))
        residual = 1e10;
    
    return residual;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nlhs == 0)
        return;

    if (nrhs == 2)
    {
        //mexPrintf("Opened MEX file\n");

        setup();
        
        vector<Phasor> measured_phasor(2);
        
        if (mxGetNumberOfElements(prhs[0]) < 2)
            mexErrMsgIdAndTxt("Mex:Error", "Not enough measurements");
        if (mxGetNumberOfElements(prhs[1]) < 2)
            mexErrMsgIdAndTxt("Mex:Error", "Not enough measurements");
        
        double* mp_r = mxGetPr(prhs[0]);
        double* mp_i = mxGetPi(prhs[0]);
        double* mi = mxGetPr(prhs[1]);
        
        measured_phasor[0].phasor.real(mp_r[0]);
        measured_phasor[0].phasor.imag(mp_i[0]);
        measured_phasor[0].I = mi[0];
        
        measured_phasor[1].phasor.real(mp_r[1]);
        measured_phasor[1].phasor.imag(mp_i[1]);
        measured_phasor[1].I = mi[1];
        
        //mexPrintf("About to create optimisation object\n");
        
        nlopt::opt opt(nlopt::LN_COBYLA, 4);
        opt.set_min_objective(&objective, (void*)(&measured_phasor));
        opt.set_xtol_rel(1e-4);
        opt.set_maxeval(1000);
        opt.set_maxtime(1.0);
        opt.set_initial_step(0.1);

        std::vector<double> x(4);
        x[0] = log(1); 
        x[1] = log(1);
        x[2] = log(1);
        x[3] = log(1);
        
        
        //mexPrintf("Starting optimisation...\n");

        double minf;
        try
        {
            nlopt::result result = opt.optimize(x, minf);
        }
        catch(...)
        {
            mexErrMsgIdAndTxt("MEX:error", "Exception occurred");
        }
        
        plhs[0] = mxCreateDoubleMatrix(1,4,mxREAL);
        double* ans = mxGetPr(plhs[0]);
        
        for(int i=0; i<4; i++)
            ans[i] = exp(x[i]);
    }
    
    //plhs[0] = mxCreateDoubleScalar(residual);
}