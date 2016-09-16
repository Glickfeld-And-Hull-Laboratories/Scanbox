#include "mex.h"

static unsigned int n, k, m;
static unsigned short int *inMatrix;                 /* 1xN input matrix [2 4 1250 nlines]*/
static unsigned short int *outMatrix;                /* [2 S nlines] uint16*/
static unsigned short int *outMatrixA, *outMatrixB;  /* [S nlines]   uint16*/
static unsigned char      *outMatrixCData;           /* [3 S nlines]   uint8*/
static unsigned int       *inIdx;                    /* [2 4 S nlines] uint32 indices into inMatrix */
static unsigned int       *outIdx;                
static unsigned int       *outIdxA;   
static unsigned int       *cdIdx;                

static unsigned short int *nlines;
static unsigned short int *dispMode;                 /* display mode */
static unsigned short int *nperline;

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
    outIdx     = (unsigned int *)       mxGetPr(prhs[2]);
    outIdxA    = (unsigned int *)       mxGetPr(prhs[3]);
    cdIdx      = (unsigned int *)       mxGetPr(prhs[4]);

    outMatrix  = (unsigned short int *) mxGetPr(prhs[5]);
    outMatrixA = (unsigned short int *) mxGetPr(prhs[6]);
    outMatrixB = (unsigned short int *) mxGetPr(prhs[7]);
    
    outMatrixCData = (unsigned char *)  mxGetPr(prhs[8]);
    
    ttl        = (unsigned short int *) mxGetPr(prhs[9]);
    nlines     = (unsigned short int *) mxGetPr(prhs[10]);
    dispMode   = (unsigned short int *) mxGetPr(prhs[11]);
    nperline   = (unsigned short int *) mxGetPr(prhs[12]);

    k=m=0;
    
    *ttl = (inMatrix[0] & 0x03);
    
    switch(*dispMode) {
        
        case 1:
            
            for(n=0;n<(*nperline)*(*nlines)/2;n++){
                
                tmp0 =  inMatrix[*inIdx++];
                tmp1 =  inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                
                v0 = (unsigned short int) (tmp0 >>2);
                v1 = (unsigned short int) (tmp1 >>2);

                outMatrix[*outIdx++] = outMatrixA[*outIdxA]   = v0;
                outMatrix[*outIdx++] = outMatrixB[*outIdxA++] = v1;
       
                if(*vh0){
                    tmp = 255 - *vh0;
                    outMatrixCData[*cdIdx++] = 0;
                    outMatrixCData[*cdIdx++] = tmp;
                    outMatrixCData[*cdIdx++] = 0;
                } else {
                    outMatrixCData[*cdIdx++] = 0xff;
                    outMatrixCData[*cdIdx++] = 0xff;
                    outMatrixCData[*cdIdx++] = 0xff;
                }

            }
            
            break;
            
        case 2:
            for(n=0;n<(*nperline)*(*nlines)/2;n++){
                
                tmp0 =  inMatrix[*inIdx++];
                tmp1 =  inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                
                v0 = (unsigned short int) (tmp0 >>2);
                v1 = (unsigned short int) (tmp1 >>2);
                
                outMatrix[*outIdx++] = outMatrixA[*outIdxA]   = v0;
                outMatrix[*outIdx++] = outMatrixB[*outIdxA++] = v1;
                
                if (*vh1) {
                    tmp = 255 - *vh1;
                    outMatrixCData[*cdIdx++] = tmp;
                    outMatrixCData[*cdIdx++] = 0;
                    outMatrixCData[*cdIdx++] = 0;
                } else {
                    outMatrixCData[*cdIdx++] = 0xff;
                    outMatrixCData[*cdIdx++] = 0xff;
                    outMatrixCData[*cdIdx++] = 0xff;
                }
            }
            break;
        default:
            
            for(n=0;n<(*nperline)*(*nlines)/2;n++){
                
                tmp0 =  inMatrix[*inIdx++];
                tmp1 =  inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                
                v0 = (unsigned short int) (tmp0 >>2);
                v1 = (unsigned short int) (tmp1 >>2);
                
                outMatrix[*outIdx++] = outMatrixA[*outIdxA]   = v0;
                outMatrix[*outIdx++] = outMatrixB[*outIdxA++] = v1;
                
                if (*vh0 * *vh1){
                    outMatrixCData[*cdIdx++] = 255 - *vh1;
                    outMatrixCData[*cdIdx++] = 255 - *vh0;
                    outMatrixCData[*cdIdx++] = 0;
                } else {
                    outMatrixCData[*cdIdx++] = 0xff;
                    outMatrixCData[*cdIdx++] = 0xff;
                    outMatrixCData[*cdIdx++] = 0xff;
                }
                
            }
            
            break;
    }
}
