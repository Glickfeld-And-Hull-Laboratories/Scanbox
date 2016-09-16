#include "mex.h"

static unsigned int n, k,m;
static unsigned short int *inMatrix;                 /* 1xN input matrix [2 4 1250 nlines]*/
static unsigned short int *outMatrix;                /* [2 S nlines] uint16*/
static unsigned short int *outMatrixA, *outMatrixB;  /* [S nlines]   uint16*/
static unsigned char      *outMatrixCData;           /* [S nlines 3]   uint8*/
static unsigned int       *inIdx;                    /* [2 S nlines] uint32 indices into inMatrix */
static unsigned short int *nlines;
static unsigned short int *dispMode;                 /* display mode */

static    unsigned short int *ttl;
static    unsigned short int v0,v1;
static    unsigned char *vh0 = (unsigned char *)(&v0)+1;
static    unsigned char *vh1 = (unsigned char *)(&v1)+1;
static    unsigned int tmp0,tmp1;
static    unsigned char tmp;

void mexFunction( int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    /* input data */
    
    inMatrix   = (unsigned short int *) mxGetPr(prhs[0]);
    inIdx      = (unsigned int *)       mxGetPr(prhs[1]);
    
    outMatrix  = (unsigned short int *) mxGetPr(prhs[2]);
    outMatrixA = (unsigned short int *) mxGetPr(prhs[3]);
    outMatrixB = (unsigned short int *) mxGetPr(prhs[4]);
    
    outMatrixCData = (unsigned char *) mxGetPr(prhs[5]);
    
    ttl        = (unsigned short int *) mxGetPr(prhs[6]);
    nlines     = (unsigned short int *) mxGetPr(prhs[7]);
    dispMode   = (unsigned short int *) mxGetPr(prhs[8]);
    
    k=m=0;
    
    *ttl = (inMatrix[0] & 0x03);
    
    for(n=0;n<796*(*nlines);n++){
        
        tmp0 =  inMatrix[inIdx[k++]];
        tmp1 =  inMatrix[inIdx[k++]];
        tmp0 += inMatrix[inIdx[k++]];
        tmp1 += inMatrix[inIdx[k++]];
        tmp0 += inMatrix[inIdx[k++]];
        tmp1 += inMatrix[inIdx[k++]];
        tmp0 += inMatrix[inIdx[k++]];
        tmp1 += inMatrix[inIdx[k++]];
        
        v0 = (unsigned short int) (tmp0 >>2);
        v1 = (unsigned short int) (tmp1 >>2);
        
        *outMatrix++ = *outMatrixA++ = v0;
        *outMatrix++ = *outMatrixB++ = v1;
        
        switch(*dispMode) {
            case 1:
                if(*vh0){
                    tmp = 255 - *vh0;
                    outMatrixCData[m++] = 0;
                    outMatrixCData[m++] = tmp;
                    outMatrixCData[m++] = 0;
                } else {
                    outMatrixCData[m++] = 0xff;
                    outMatrixCData[m++] = 0xff;
                    outMatrixCData[m++] = 0xff;
                }
                
                break;
                
            case 2:
                if (*vh1) {
                    tmp = 255 - *vh1;
                    outMatrixCData[m++] = tmp;
                    outMatrixCData[m++] = 0;
                    outMatrixCData[m++] = 0;
                } else {
                    outMatrixCData[m++] = 0xff;
                    outMatrixCData[m++] = 0xff;
                    outMatrixCData[m++] = 0xff;
                }
                break;
                
            default:
                
            if (*vh0 * *vh1){
                outMatrixCData[m++] = 255 - *vh1;
                outMatrixCData[m++] = 255 - *vh0;
                outMatrixCData[m++] = 0;}
            else {
                outMatrixCData[m++] = 0xff;
                outMatrixCData[m++] = 0xff;
                outMatrixCData[m++] = 0xff;
            }
            break;

        }
    }
}