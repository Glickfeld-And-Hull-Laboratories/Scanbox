#include "mex.h"

static unsigned int n, k,m;
static unsigned short int *inMatrix;                 /* 1xN input matrix [2 4 1250 nlines]*/
static unsigned short int *outMatrix;                /* [2 S nlines] uint16*/
static unsigned short int *outMatrixA, *outMatrixB;  /* [S nlines]   uint16*/
static unsigned char      *outMatrixCData;           /* [3 S nlines]   uint8*/
static unsigned int       *inIdx;                    /* [2 4 S nlines] uint32 indices into inMatrix */
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
    
    switch(*dispMode) {
        
        case 1:
            
            for(n=0;n<796*(*nlines);n++){
                
                tmp0 =  inMatrix[*inIdx++];
                tmp1 =  inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                tmp0 += inMatrix[*inIdx++];
                tmp1 += inMatrix[*inIdx++];
                
                v0 = (unsigned short int) (tmp0);
                v1 = (unsigned short int) (tmp1);
                
                *outMatrix++ = *outMatrixA++ = (v0>>2);
                *outMatrix++ = *outMatrixB++ = (v1>>2);
                
                if(*vh0){
                    tmp = 255 - *vh0;
                    *outMatrixCData++ = tmp;
                    *outMatrixCData++ = tmp;
                    *outMatrixCData++ = tmp;
                } else {
                    *outMatrixCData++ = 0xff;
                    *outMatrixCData++ = 0x00;
                    *outMatrixCData++ = 0x00;
                }
            }
            
            break;
            
        case 2:
            for(n=0;n<796*(*nlines);n++){
                
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
                
                *outMatrix++ = *outMatrixA++ = v0;
                *outMatrix++ = *outMatrixB++ = v1;
                
                if (*vh1) {
                    tmp = 255 - *vh1;
                    *outMatrixCData++ = tmp;
                    *outMatrixCData++ = tmp;
                    *outMatrixCData++ = tmp;
                } else {
                    *outMatrixCData++ = 0xff;
                    *outMatrixCData++ = 0x00;
                    *outMatrixCData++ = 0x00;
                }
            }
            break;
        default:
            
            for(n=0;n<796*(*nlines);n++){
                
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
                
                *outMatrix++ = *outMatrixA++ = v0;
                *outMatrix++ = *outMatrixB++ = v1;
                
                if (*vh0 * *vh1){
                    *outMatrixCData++ = 255 - *vh1;
                    *outMatrixCData++ = 255 - *vh0;
                    *outMatrixCData++ = 0;}
                else {
                    *outMatrixCData++ = 0xff;
                    *outMatrixCData++ = 0xff;
                    *outMatrixCData++ = 0xff;
                }
                
            }
            
            break;
    }
}
