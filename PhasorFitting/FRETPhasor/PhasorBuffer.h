#include <complex>
#include <vector>
#include <mex.h>
#include <math.h>

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
    
    Phasor()
    {}
    
    Phasor(float r, float i)
    {
        phasor.real(r);
        phasor.imag(i);
        I = 1;
        A = 1;
    }
    
    Phasor& operator+=(const Phasor& other) 
    {
        float newA = A + other.A;
        if (newA < 1e-5)
        {
            phasor = 0.0f;
            I = 0.0f;
        }
        else
        {            
            phasor = (A * phasor + other.A * other.phasor) / newA;
            I = (A * I + other.A * other.I) / newA;
        }
        A = newA;
        return *this;
    }

    Phasor& operator*=(float v) 
    {
        //I *= v;
        A *= v;
        return *this;
    }

    Phasor& operator/=(float v) 
    {
        //I /= v;
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


void printPhasor(const Phasor& phasor)
{
    mexPrintf("   P: %f + %f i, I: %f \n", phasor.phasor.real(), phasor.phasor.imag(), phasor.I);
}



class PhasorBuffer
{
public:
       
    
    void get(float k, vector<Phasor>& phasor, float Qf1 = 1.0f, float Qf2 = 1.0f)
    {
        if ((Qf1 != 1.0f) || (Qf2 != 1.0f))
        {
            calculate(k, phasor, Qf1, Qf2);
            //mexPrintf("Getting phasor at k=%f\n", k);
            return;
        }

        if (k < 0)
            k = 0;
        
        float idxf = k / k_max * (n-1); 
        
        int idx = idxf;
        float di = idxf - idx;
        
        //mexPrintf("Getting phasor at k=%f, idx=%d, di=%f\n", k, idx, di);
        
        if ((k > k_max) || idx >= (n-1))
        {
            idx = n - 2;
            di = 1;
        }
        
        phasor.resize(n_channel);
        for(int i=0; i<n_channel; i++)
        {
            phasor[i] = (1-di) * phasor_buffer[idx][i];
            phasor[i] += di * phasor_buffer[idx+1][i]; 
        }
        /*
        auto test1 = phasor;
        vector<Phasor> test2;
        calculate(k, test2, Qf1, Qf2);
        for(int i=0; i<n_channel; i++)
        {
           auto A = test1[i].A - test2[i].A;
           auto I = test1[i].I - test2[i].I;
           mexPrintf("diff : %f, %f\n", A, I);
        }
         */
    }
    
    void setSystem(const System& s_)
    {
        mexPrintf("Calculating buffers...\n");
        s = s_;
        phasor_buffer.assign(n, vector<Phasor>(n_channel));
     
        for(int i=0; i<n; i++)
        {
            float k = (k_max / (n-1.0f)) * i;
            calculate(k, phasor_buffer[i]);
        }
    }
        
protected:
    
    void calculate(float k, vector<Phasor>& phasor, float Qf1 = 1.0, float Qf2 = 1.0)
    {
        if (use_static)
                staticFRETphasor(k, phasor, Qf1, Qf2);
            else
                FRETphasor(k, phasor, Qf1, Qf2);
    }
    
    System s;
    float k_max = 20;
    int n = 10000;
    
    bool use_static = false;
    
    vector<vector<Phasor>> phasor_buffer;
    
    void FRETphasor(float k, vector<Phasor>& phasor, float Qf1 = 1.0f, float Qf2 = 1.0f)
    {
        float A[n_donor_components][n_acceptor_components];
        float tauDA[n_donor_components];
        phasor.resize(n_channel);

        float sigmaQ = s.sigmaQ * Qf1;
        float Qdash = s.Qdash * Qf2;

        for(int i=0; i<n_donor_components; i++)
        {
            for(int m=0; m<n_acceptor_components; m++)
            {
                float denom = s.tauA[m] * (1+k) - s.tauD[i];
                if (abs(denom) < 1e-4)
                    denom = copysign(1e-4, denom);
                A[i][m] = k / denom;
            }

            tauDA[i] = s.tauD[i] / (1 + k);
        }


        for(int j=0; j<n_channel; j++)
        {
            phasor[j].phasor = complex<float>(0.0f,0.0f);
            phasor[j].I = 0.0f;
            phasor[j].A = 0.0f;

            for(int i=0; i<n_donor_components; i++)
            {
                for(int m=0; m<n_acceptor_components; m++)
                {
                    complex<float> FD = (s.aD[j] / s.tauD[i] - A[i][m] * Qdash * s.aA[j]) * tauDA[i];
                    complex<float> FA = (sigmaQ / s.tauA[m] + A[i][m] * Qdash) * s.aA[j] * s.tauA[m];

                    Phasor p;
                    p.phasor = (FD * r(tauDA[i]) + FA * r(s.tauA[m])) / (FD + FA);

                    p.I = tauDA[i] * s.aD[j];
                    p.I += sigmaQ * s.tauA[m] * s.aA[j];
                    p.I += Qdash * s.tauA[m] * s.aA[j] * A[i][m] * (s.tauA[m] - tauDA[i]) ;

                    p.A = s.alphaD[i] * s.alphaA[m];

                    phasor[j] += p;
                }
            }
        }    
        
    }        

    void staticFRETphasor(float k, vector<Phasor>& phasor, float Qf1 = 1.0f, float Qf2 = 1.0f)
    {
        if (k < 1e-3)
        {
            FRETphasor(k, phasor, Qf1, Qf2);
            return;
        }
        
        phasor.resize(n_channel);

        for(int j=0; j<n_channel; j++)
        {
            phasor[j].phasor = complex<float>(0.0f,0.0f);
            phasor[j].I = 0.0f;
            phasor[j].A = 0.0f;
        }

        float F = 3.0 / 2.0 * k;

        int ns = 1000;

        float Emax = 1; //4.0 * F / (1.0 + 4.0 * F);
        float dE = Emax/ns;
        float sum_p = 0;

        float Ethresh = F/(1+F);

        float Eavg = 0;

        for (int i=0; i<ns; i++)
        {
            float E = (i + 1) * dE;

            if (E >= (4.0 * F / (1.0 + 4.0 * F)))
                continue;

            float p = 1.0/(2.0*(1-E)*sqrt(3.0*E*F*(1-E)));

            float q = E/(F*(1-E));
            p = p * ((E < Ethresh) ? 
                             log(2+sqrt(3)) 
                           : log((2 + sqrt(3))/(sqrt(q)+sqrt(q-1))));
            p *= dE;

            //mexPrintf("%f, ",p);

            sum_p += p;

            Eavg += p * E;

            float kE = E / (1-E);
            vector<Phasor> Ephasor(n_channel);
            FRETphasor(kE, Ephasor, Qf1, Qf2);
            for(int i=0; i<n_channel; i++)
            {
                //mexPrintf("(%f, %f), ",kE,E);
                //printPhasor(Ephasor[i]);
                phasor[i] += p * Ephasor[i];
            }
        }

        Eavg /= sum_p;

        //mexPrintf("sumP => %f, (%f)\n", sum_p,phasor[2].I);
        for(int i=0; i<n_channel; i++)
            phasor[i] /= sum_p;

    }
    
    complex<float> r(float tau)
    {
        return 1.0f / (1.0f-complex<float>(0,omega*tau));
    }

    
};
