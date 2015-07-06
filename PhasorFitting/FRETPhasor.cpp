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

const int n_channel = 3;
const int n_constructs = 2;
const int n_donor_components = 2;
struct System
{
    float sigmaQ;
    float Qdash;
    float aD[n_channel];
    float aA[n_channel];
    float tauD[n_donor_components];
    float alphaD[n_donor_components];
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
    s_CFP.sigmaQ = 1.123/10.84;
    s_CFP.Qdash = 1.9;
    s_CFP.aD[0] = 0.0698; //0.0495; // 617/73
    s_CFP.aD[1] = 0.3445; //0.4425; // 525/50
    s_CFP.aD[2] = 0.4433; // 438/32
    s_CFP.aA[0] = 0.1211; 
    s_CFP.aA[1] = 0.6717; 
    s_CFP.aA[2] = 0.0023;
    s_CFP.tauD[0] = 2824.5;
    s_CFP.tauD[1] = 861.3;
    s_CFP.alphaD[0] = 0.6345;
    s_CFP.alphaD[1] = 0.3655;
    s_CFP.tauA = 3000;
    
    s_GFP.sigmaQ = 0; //3.545/11.84;
    s_GFP.Qdash = 0.416;
    s_GFP.aD[0] = 0.0865; //0.0501;  // 617/73
    s_GFP.aD[1] = 0.7578;  // 525/50
    s_GFP.aD[2] = 0.2248; //0.1461;  // 438/32
    s_GFP.aA[0] = 0.5967;
    s_GFP.aA[1] = 0.0302;
    s_GFP.aA[2] = 0.0000;
    s_GFP.tauD[0] = 2530;
    s_GFP.tauD[1] = 1000;
    s_GFP.alphaD[0] = 1;
    s_GFP.alphaD[1] = 0;
    s_GFP.tauA = 1800;
}


void FRETphasor(const System& s, float k, vector<Phasor>& phasor)
{
    float A[n_constructs], tauDA[n_constructs];
    phasor.resize(n_channel);
    
    for(int j=0; j<n_channel; j++)
        phasor[j].I = 0;
    
    for(int i=0; i<n_donor_components; i++)
    {
        A[i] = k * s.alphaD[i] / (s.tauA - s.tauD[i] + k);
        tauDA[i] = s.tauD[i] / (1 + k);
        
        for(int j=0; j<n_channel; j++)
        {            
            phasor[j].I += (s.alphaD[i] * tauDA[i] * s.aD[j]);
            phasor[j].I += (s.alphaD[i] * s.tauA * s.sigmaQ * s.aA[j]);
            phasor[j].I += (s.alphaD[i] * s.sigmaQ * k * s.tauA / (s.tauA * (1+k) - s.tauD[i]) * (s.tauA - tauDA[i]) * s.aA[j]);
        }
    }

    for(int j=0; j<n_channel; j++)
    {
        complex<float> FD1 = 0, FD2 = 0;
        complex<float> FA1 = 0, FA2 = 0;
        
        for(int i=0; i<n_donor_components; i++)
        {
            complex<float> FD = s.alphaD[i] * (s.aD[j] / s.tauD[i] - A[i] * s.Qdash * s.aA[j]);
            complex<float> FA = s.alphaD[i] * (s.sigmaQ * s.aA[j] / s.tauA + A[i] * s.Qdash * s.aA[j]);

            FD1 += FD * r(tauDA[i]);
            FD2 += FD * tauDA[i];

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
    phasor.resize(n_channel);
    float F = 3.0 / 2.0 * k;
    
    int n = 20;
    
    float Emax = 1; //4.0 * F / (1.0 + 4.0 * F);
    float dE = Emax/n;
    float sum_p = 0;

    vector<Phasor> Ephasor(n_channel);
    
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
        for(int i=0; i<n_channel; i++)
            phasor[i] += p * Ephasor[i];
    }
    
    for(int i=0; i<n_channel; i++)
        phasor[i] /= sum_p;

}

vector<Phasor> systemPhasor(float A_CFP, float A_GFP, float k_CFP, float k_GFP)
{    
    //mexPrintf("A: %f, %f, k: %f, %f\n", A_CFP, A_GFP, k_CFP, k_GFP);
    vector<Phasor> cfp, gfp;
    
    //staticFRETphasor(s_CFP, k_CFP, cfp);
    //staticFRETphasor(s_GFP, k_GFP, gfp);
    FRETphasor(s_CFP, k_CFP, cfp);
    FRETphasor(s_GFP, k_GFP, gfp);

    vector<Phasor> phasor(n_channel);
    for(int i=0; i<n_channel; i++)
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
    for (int i=0; i<n_channel; i++)
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

    // Get phasor of given system
    if (nrhs == 4 && nlhs == 2)
    {
        setup();
        
        double A_CFP = mxGetScalar(prhs[0]);
        double A_GFP = mxGetScalar(prhs[1]);
        double k_CFP = mxGetScalar(prhs[2]);
        double k_GFP = mxGetScalar(prhs[3]);
        
        vector<Phasor> phasor = systemPhasor(A_CFP, A_GFP, k_CFP, k_GFP);
        
        plhs[0] = mxCreateDoubleMatrix(1, n_channel, mxCOMPLEX);
        plhs[1] = mxCreateDoubleMatrix(1, n_channel, mxREAL);
        
        double* mp_r = mxGetPr(plhs[0]);
        double* mp_i = mxGetPi(plhs[0]);
        double* mi = mxGetPr(plhs[1]);

        for(int i=0; i<n_channel; i++)
        {
            mp_r[i] = phasor[i].phasor.real();
            mp_i[i] = phasor[i].phasor.imag();
            mi[i] = phasor[i].I;
        }
        
        return;
    }
           
    
    if (nrhs == 2)
    {
        //mexPrintf("Opened MEX file\n");

        setup();
        
        vector<Phasor> measured_phasor(n_channel);
        
        if (mxGetNumberOfElements(prhs[0]) < n_channel)
            mexErrMsgIdAndTxt("Mex:Error", "Not enough measurements");
        if (mxGetNumberOfElements(prhs[1]) < n_channel)
            mexErrMsgIdAndTxt("Mex:Error", "Not enough measurements");
                
        double* mp_r = mxGetPr(prhs[0]);
        double* mp_i = mxGetPi(prhs[0]);
        double* mi = mxGetPr(prhs[1]);
        
        for(int j=0; j<n_channel; j++)
        {
            measured_phasor[j].phasor.real(mp_r[j]);
            measured_phasor[j].phasor.imag(mp_i[j]);
            measured_phasor[j].I = mi[j];
        }
        
        //mexPrintf("About to create optimisation object\n");
        
        nlopt::opt opt(nlopt::LN_COBYLA, 4);
        opt.set_min_objective(&objective, (void*)(&measured_phasor));
        opt.set_xtol_rel(1e-4);
        opt.set_maxeval(10000);
        opt.set_maxtime(10.0);
        opt.set_initial_step(0.1);

        std::vector<double> x(2*n_constructs);
        for(int i=0; i<n_constructs; i++)
        {
            x[i] = log(0.01); // I
            x[i+n_constructs] = log(0.5); // k
        }        
                
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
        
        plhs[0] = mxCreateDoubleMatrix(1,n_constructs*2+1,mxREAL);
        double* ans = mxGetPr(plhs[0]);
        
        for(int i=0; i<n_constructs*2; i++)
            ans[i] = exp(x[i]);
        ans[n_constructs*2] = minf;
    }
    
    //plhs[0] = mxCreateDoubleScalar(residual);
}