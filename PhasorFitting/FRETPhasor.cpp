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
const int n_acceptor_components = 2;

struct System
{
    float sigmaQ;
    float Qdash;
    float aD[n_channel];
    float aA[n_channel];
    float tauD[n_donor_components];
    float alphaD[n_donor_components];
    float tauA[n_acceptor_components];
    float alphaA[n_acceptor_components];
};

class Phasor
{
public:
    complex<float> phasor;
    float I = 0;
    float A = 0;
    
    Phasor& operator+=(const Phasor& other) 
    {
        float newA = A + other.A;
        phasor = (A * phasor + other.A * other.phasor) / newA;
        I = (A * I + other.A * other.I) / newA;
        A = newA;
        return *this;
    }

    Phasor& operator*=(float v) 
    {
        I *= v;
        A *= v;
        return *this;
    }

    Phasor& operator/=(float v) 
    {
        I /= v;
        A /= v;
        return *this;
    }
};

Phasor operator+(const Phasor& p1, const Phasor& p2) 
{
    Phasor p = p1;
    p += p2;
    return p;
}

Phasor operator*(const Phasor& p1, float v) 
{
    Phasor p = p1;
    p *= v;
    return p;
}

Phasor operator*(float v, const Phasor& p1) 
{
    Phasor p = p1;
    p *= v;
    return p;
}

Phasor operator/(const Phasor& p1, float v) 
{
    Phasor p = p1;
    p /= v;
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
    s_CFP.sigmaQ = 1.1233 / 10.849 * 1.779; //2.123/10.84;
    s_CFP.Qdash = 1.9 * 1.731;
    s_CFP.aD[0] = 0.0698; //0.0495; // 617/73
    s_CFP.aD[1] = 0.3445; //0.4425; // 525/50
    s_CFP.aD[2] = 0.4433; // 438/32
    s_CFP.aA[0] = 0.1610; //0.1211; 
    s_CFP.aA[1] = 0.6717; 
    s_CFP.aA[2] = 0.0038; //0.0023;
    s_CFP.tauD[0] = 2824.5;
    s_CFP.tauD[1] = 861.3;
    s_CFP.alphaD[0] = 0.6345;
    s_CFP.alphaD[1] = 0.3655;
    s_CFP.tauA[0] = 2850;
    s_CFP.tauA[1] = 1000;
    s_CFP.alphaA[0] = 1;
    s_CFP.alphaA[1] = 0;
    
    s_GFP.sigmaQ = 3.545/11.535 * 0.8117;
    s_GFP.Qdash = 0.416 * 1.6675;
    s_GFP.aD[0] = 0.0865; //0.0501;  // 617/73
    s_GFP.aD[1] = 0.7578;  // 525/50
    s_GFP.aD[2] = 0.2248; //0.1461;  // 438/32
    s_GFP.aA[0] = 0.5967;
    s_GFP.aA[1] = 0.0000;
    s_GFP.aA[2] = 0.0000;
    s_GFP.tauD[0] = 2530;
    s_GFP.tauD[1] = 1000;
    s_GFP.alphaD[0] = 1;
    s_GFP.alphaD[1] = 0;
    s_GFP.tauA[0] = 2050;
    s_GFP.tauA[1] = 1000;
    s_GFP.alphaA[0] = 0.4562;
    s_GFP.alphaA[1] = 0.5438;
}


void FRETphasor(const System& s, float k, vector<Phasor>& phasor, float Qf1, float Qf2)
{
    float A[n_donor_components][n_acceptor_components];
    float tauDA[n_donor_components];
    phasor.resize(n_channel);
    
    float sigmaQ = s.sigmaQ * Qf1;
    float Qdash = s.Qdash * Qf2;
    
    for(int j=0; j<n_channel; j++)
        phasor[j].I = 0;
    
    for(int i=0; i<n_donor_components; i++)
    {
        for(int m=0; m<n_acceptor_components; m++)
            A[i][m] = k / (s.tauA[m] * (1+k) - s.tauD[i]);
        
        tauDA[i] = s.tauD[i] / (1 + k);
    }

    
    for(int j=0; j<n_channel; j++)
    {
        phasor[j].phasor = complex<float>(0.0f,0.0f);
        phasor[j].I = 0.0f;
        
        for(int i=0; i<n_donor_components; i++)
        {
            for(int m=0; m<n_acceptor_components; m++)
            {
                complex<float> FD = s.aD[j] / s.tauD[i] - A[i][m] * Qdash * s.aA[j];
                complex<float> FA = (sigmaQ / s.tauA[m] + A[i][m] * Qdash) * s.aA[j];

                Phasor p;
                p.phasor = (FD * r(tauDA[i]) + FA * r(s.tauA[m])) / (FD * tauDA[i] + FA * s.tauA[m]);

                p.I = tauDA[i] * s.aD[j];
                p.I += sigmaQ * s.tauA[m] * s.aA[j];
                p.I += Qdash * s.tauA[m] * s.aA[j] * A[i][m] * (s.tauA[m] - tauDA[i]) ;

                p.A = s.alphaD[i] * s.alphaA[m];

                phasor[j] += p;
            }
        }
    }    
}        


void printPhasor(const Phasor& phasor)
{
    mexPrintf("   P: %f + %f i, I: %f \n", phasor.phasor.real(), phasor.phasor.imag(), phasor.I);
}

/*
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
*/
vector<Phasor> systemPhasor(float A_CFP, float A_GFP, float k_CFP, float k_GFP, float m_CFP1 = 1.0f, float m_CFP2 = 1.0f, float m_GFP1 = 1.0f, float m_GFP2 = 1.0f)
{    
    //mexPrintf("A: %f, %f, k: %f, %f\n", A_CFP, A_GFP, k_CFP, k_GFP);
    vector<Phasor> cfp, gfp;
    
    //staticFRETphasor(s_CFP, k_CFP, cfp);
    //staticFRETphasor(s_GFP, k_GFP, gfp);
    FRETphasor(s_CFP, k_CFP, cfp, m_CFP1, m_CFP2);
    FRETphasor(s_GFP, k_GFP, gfp, m_GFP1, m_GFP2);

    vector<Phasor> phasor(n_channel);
    for(int i=0; i<n_channel; i++)
        phasor[i] = A_CFP * cfp[i] + A_GFP * gfp[i]; 

    return phasor;
}

double residual(const vector<Phasor>& measured_phasor, const vector<Phasor>& phasor)
{
    float residual = 0;
    for (int i=0; i<n_channel; i++)
    {
        complex<float> p_diff = phasor[i].phasor - measured_phasor[i].phasor;
        float I_diff = (phasor[i].I - measured_phasor[i].I) / measured_phasor[i].I;
        float ri = p_diff.real()*p_diff.real() + p_diff.imag()*p_diff.imag() + I_diff*I_diff;
        residual += ri;
    }
    
    if(!isfinite(residual))
        residual = 1;

    return residual;
}

double objective(unsigned n, const double* x, double* grad, void* f_data)
{
    vector<Phasor>& measured_phasor = *((vector<Phasor>*)f_data);
    
    float A_CFP = exp(x[0]);
    float A_GFP = exp(x[1]);
    float k_CFP = exp(x[2]);
    float k_GFP = exp(x[3]);
        
    vector<Phasor> phasor = systemPhasor(A_CFP, A_GFP, k_CFP, k_GFP);
    
    return residual(measured_phasor, phasor);
}

double objectiveFixedK(unsigned n, const double* x, double* grad, void* f_data)
{
    vector<Phasor>& measured_phasor = *((vector<Phasor>*)f_data);
    
    float A_CFP = exp(x[0]);
    float A_GFP = exp(x[1]);
    float k_CFP = 0.2; 
    float k_GFP = 0.2;
        
    vector<Phasor> phasor = systemPhasor(A_CFP, A_GFP, k_CFP, k_GFP);
    
    return residual(measured_phasor, phasor);
}


double objectiveQ(unsigned n, const double* x, double* grad, void* f_data)
{
    vector<Phasor>& measured_phasor = *((vector<Phasor>*)f_data);
    
    float A = exp(x[0]);
    float k = exp(x[1]);
    float m1 = x[2];
    float m2 = x[3];
    
    //vector<Phasor> phasor = systemPhasor(0, A, 0, k, 1.0f, 1.0f, m1, m2);
    vector<Phasor> phasor = systemPhasor(A, 0, k, 1, m1, m2, 1.0f, 1.0f);
    
    double res = residual(measured_phasor, phasor);
    
    //mexPrintf("%f, %f, %f, %f -> %f\n", A, k, m1, m2, res);
    
    return res;
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
        
        vector<Phasor> phasor = systemPhasor(A_CFP, A_GFP, k_CFP, k_GFP, 1.0f, 1.0f);
        
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
           
    
    if (nrhs == 2 || nrhs == 3)
    {
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
        
        if (nrhs == 2)
        {
            nlopt::opt opt(nlopt::LN_BOBYQA, 2);
            opt.set_min_objective(&objectiveFixedK, (void*)(&measured_phasor));
            opt.set_xtol_rel(1e-4);
            opt.set_maxeval(1000);
            opt.set_maxtime(1.0);
            //opt.set_initial_step(0.1);

            std::vector<double> x(n_constructs);
            for(int i=0; i<n_constructs; i++)
                x[i] = log(0.1); // I

            double minf;
            nlopt::result result = opt.optimize(x, minf);

          
            nlopt::opt opt2(nlopt::LN_BOBYQA, 4);
            opt2.set_min_objective(&objective, (void*)(&measured_phasor));
            opt2.set_xtol_rel(1e-4);
            opt2.set_maxeval(10000);
            opt2.set_maxtime(10.0);
            //opt2.set_initial_step(0.01);

            for(int i=0; i<n_constructs; i++)
                x.push_back(log(0.2));
            
            
            result = opt2.optimize(x, minf);
            
            
            plhs[0] = mxCreateDoubleMatrix(1,n_constructs*2+1,mxREAL);
            double* ans = mxGetPr(plhs[0]);

            for(int i=0; i<n_constructs*2; i++)
                ans[i] = exp(x[i]);
            ans[n_constructs*2] = minf;
        }
        else
        {
            nlopt::opt opt(nlopt::LN_BOBYQA, 4);
            opt.set_min_objective(&objectiveQ, (void*)(&measured_phasor));
            opt.set_xtol_rel(1e-4);
            opt.set_maxeval(10000);
            opt.set_maxtime(10.0);
            opt.set_initial_step(0.1);

            std::vector<double> x(4);
            x[0] = log(1);
            x[1] = log(0.2);
            x[2] = 1;
            x[3] = 1;

            double minf;
            try
            {
                nlopt::result result = opt.optimize(x, minf);
                mexPrintf("Result: %d\n", result);
            }
            catch(...)
            {
                mexErrMsgIdAndTxt("MEX:error", "Exception occurred");
            }

            plhs[0] = mxCreateDoubleMatrix(1,5,mxREAL);
            double* ans = mxGetPr(plhs[0]);

            ans[0] = exp(x[0]);
            ans[1] = exp(x[1]);
            ans[2] = x[2];
            ans[3] = x[3];
            ans[4] = minf;   
        }
            
    }
    
}