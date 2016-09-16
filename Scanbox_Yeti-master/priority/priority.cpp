/*

CHANGE LOG:

	2009-09-18	V2	(mitch) removed restriction on "h" priority following user request. i suppose
					we can take responsibility for our own actions. also improved usage notes.

*/

#include "mex.h"		// necessary
#include "windows.h"

/* Input Arguments */
#define	PRI	prhs[0]

void usage()
{
	printf(

"\n"
"Usage:   q = priority(p)\n\n"
"         Set the priority of the Matlab process to that specified\n"
"         in \"p\". \"p\" can be any of the following: \"l\", \"bn\", \"n\",\n"
"         \"an\" or \"h\" (low, below-normal, normal, above-normal, high).\n"
"         In addition, \"s\" can be prefixed to any of these to cause\n"
"         silent behaviour (no message printed). The previous priority\n"
"         is returned in \"q\", in the same format.\n\n"
"         q = priority\n\n"
"         Just return the current priority without changing anything.\n"
"\n"
"Example: q = priority('l'); %% reduce priority\n"
"         ...\n"
"         <do some heavy processing without freezing computer>\n"
"         ...\n"
"         priority(q); %% restore priority\n\n"
"         This is Version 2 (2009-09-18).\n"
"\n"

);
}

void mexFunction(
	int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[])
{
	bool silent = false;

	if (nlhs==0 && nrhs==0)
	{
		usage();
		return;
	}

	if (nlhs>0)
	{
		HANDLE Proc = GetCurrentProcess();
		DWORD Pri = GetPriorityClass(Proc);
		if (!Pri) mexErrMsgTxt("Could not get priority");
		char buf[16];
		if (Pri==IDLE_PRIORITY_CLASS)			sprintf(buf,"l");
		else if (Pri==16384)					sprintf(buf,"bn"); // only exists on 2000+ i think
		else if (Pri==NORMAL_PRIORITY_CLASS)	sprintf(buf,"n");
		else if (Pri==32768)					sprintf(buf,"an"); // only exists on 2000+ i think
		else sprintf(buf,"h");
		plhs[0] = mxCreateString(buf);
	}

	if (nrhs>0)
	{
		if (mxGetM(PRI)!=1 || !mxIsChar(PRI) || mxGetN(PRI)>3 || mxGetN(PRI)<1)
		{
			usage();
			return;
		}

		int buflen = (mxGetN(prhs[0])) + 1;
		char* buf=(char*)mxCalloc(buflen, sizeof(char));
		int status = mxGetString(prhs[0], buf, buflen);
		if(status != 0) mexErrMsgTxt("Failed");

		if (strncmp(buf,"s",1)==0)
		{
			buf++;
			silent = true;
		}

		DWORD Pri;
		if (strcmp(buf,"l")==0) Pri=IDLE_PRIORITY_CLASS;
		else if (strcmp(buf,"bn")==0) Pri=16384;
		else if (strcmp(buf,"n")==0) Pri=NORMAL_PRIORITY_CLASS;
		else if (strcmp(buf,"an")==0) Pri=32768;
		else if (strcmp(buf,"h")==0) Pri=HIGH_PRIORITY_CLASS; // now allowed!
		else mexErrMsgTxt("Unrecognised priority level - should be l/bn/n/an/h");

		HANDLE Proc = GetCurrentProcess();
		if (!SetPriorityClass(Proc,Pri)) mexErrMsgTxt("Could not set priority");
		else { if (!silent) printf("Priority set OK.\n"); }
	}

	return;
}

