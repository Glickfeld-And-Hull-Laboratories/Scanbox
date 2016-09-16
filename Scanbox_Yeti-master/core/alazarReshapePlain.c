#include "mex.h"

void mexFunction( int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
        
    unsigned int pix,row,col,chan,k;
    unsigned short int *inMatrix;                 /* 1xN input matrix [2 4 1250 nlines]*/
    unsigned short int *outMatrix;                /* [2 S nlines] uint16*/
    unsigned short int *outMatrixA, *outMatrixB;  /* [S nlines]   uint16*/
    unsigned char      *outMatrixAd, *outMatrixBd;  /* [S nlines]   uint8*/
    unsigned char      *outMatrixAa, *outMatrixBa;  /* [S nlines]   uint8*/   
    unsigned int       *inIdx;                    /* [2 S nlines] uint32 indices into inMatrix */
    unsigned short int *nlines; 
    unsigned short int *ttl;
    unsigned short int v[2];
    unsigned char *vh0,*vh1;
    
    /* input data */
    
    inMatrix   = (unsigned short int *) mxGetPr(prhs[0]);
    inIdx      = (unsigned int *)       mxGetPr(prhs[1]); 
    
    outMatrix  = (unsigned short int *) mxGetPr(prhs[2]);
    outMatrixA = (unsigned short int *) mxGetPr(prhs[3]);
    outMatrixB = (unsigned short int *) mxGetPr(prhs[4]);
    
    outMatrixAd = (unsigned char *) mxGetPr(prhs[5]);
    outMatrixBd = (unsigned char *) mxGetPr(prhs[6]);
    
    ttl        = (unsigned short int *) mxGetPr(prhs[7]);
    nlines     = (unsigned short int *) mxGetPr(prhs[8]);
    
    k=0;
    
    vh0 = (unsigned char *) &v[0]; vh0++;
    vh1 = (unsigned char *) &v[1]; vh1++;
    
    *ttl = (inMatrix[0] & 0x03);
    
    for(row=0;row<*nlines;row++)        
        for(col=0;col<796;col++){
            
            v[0] = v[1] = 0;
            for(pix=0;pix<4;pix++)
                for(chan=0;chan<2;chan++) {
                    v[chan] += (inMatrix[inIdx[k++]] >> 2);
                }
            
            *outMatrix++ = *outMatrixA++ = v[0];
            *outMatrixAd++ = *vh0;
            
            *outMatrix++ = *outMatrixB++ = v[1];   
            *outMatrixBd++ = *vh1;

        }
}