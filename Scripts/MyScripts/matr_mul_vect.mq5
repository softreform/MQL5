//+------------------------------------------------------------------+
//|                                                matr_mul_vect.mq5 |
//+------------------------------------------------------------------+
#property script_show_inputs

#define ROWS1       2000      // rows in the first matrix
#define COLSROWS    2000      // columns in the first matrix = rows in the second matrix 
#define COLS2       2000      // columns in the second matrix
#define REALTYPE    float

REALTYPE first[ ];            // first linear buffer (matrix)   rows1 * colsrows
REALTYPE second[ ];           // second buffer                  colsrows * cols2
REALTYPE thirdGPU[ ];         // product - also a buffer        rows1 * cols2
REALTYPE thirdCPU[ ];         // product - also a buffer        rows1 * cols2

input int _device=1;          // here is the device; it can be changed

string d2s(double arg,int dig) { return DoubleToString(arg,dig); }
string i2s(int arg) { return IntegerToString(arg); }

//+------------------------------------------------------------------+
const string clSrc=
                   "#define COLS2     "+i2s(COLS2)+"                                       \r\n"
                   "#define COLSROWS  "+i2s(COLSROWS)+"                                    \r\n"
                   "#define REALTYPE  float                                                \r\n"
                   "#define REALTYPE4 float4                                               \r\n"
                   "                                                                       \r\n"
                   "__kernel void matricesMul( __global REALTYPE *in1,                     \r\n"
                   "                           __global REALTYPE *in2,                     \r\n"
                   "                           __global REALTYPE *out  )                   \r\n"
                   "{                                                                      \r\n"
                   "  int r = get_global_id( 0 );                                          \r\n"
                   "  REALTYPE rowbuf[ COLSROWS ];                                         \r\n"
                   "  for( int col = 0; col < COLSROWS; col ++ )                           \r\n"
                   "  {                                                                    \r\n"
                   "     rowbuf[ col ] =  in1[r * COLSROWS + col ];                        \r\n"
                   "  }                                                                    \r\n"
                   "                                                                       \r\n"
                   "  REALTYPE sum;                                                        \r\n"
                   "                                                                       \r\n"
                   "  for( int c = 0; c < COLS2; c ++ )                                    \r\n"
                   "  {                                                                    \r\n"
                   "     sum = 0.0;                                                        \r\n"
                   "     for( int cr = 0; cr < COLSROWS; cr += 4 )                         \r\n"
                   "        sum += dot( ( REALTYPE4 ) ( rowbuf[ cr ],                      \r\n"
                   "                                    rowbuf[ cr + 1 ],                  \r\n"
                   "                                    rowbuf[ cr + 2 ],                  \r\n"
                   "                                    rowbuf[ cr + 3 ] ),                \r\n"
                   "                    ( REALTYPE4 ) ( in2[c * COLSROWS + cr     ],       \r\n"
                   "                                    in2[c * COLSROWS + cr + 1 ],       \r\n"
                   "                                    in2[c * COLSROWS + cr + 2 ],       \r\n"
                   "                                    in2[c * COLSROWS + cr + 3 ] ) );   \r\n"
                   "     out[ r * COLS2 + c ] = sum;                                       \r\n"
                   "  }                                                                    \r\n"
                   "}                                                                      \r\n";
//+------------------------------------------------------------------+
//| mulCPUOneCore                                                    |
//| main matrix multiplication function;                             |
//| input matrices are already generated,                            |
//| the output matrix is initialized to zeros                        |
//+------------------------------------------------------------------+
void mulCPUOneCore()
  {
// c-r-cr: 11.544 s 
//st = GetTickCount( );

   for(int c=0; c<COLS2; c++)
      for(int r=0; r<ROWS1; r++)
         for(int cr=0; cr<COLSROWS; cr++)
            thirdCPU[r*COLS2+c]+=first[r*COLSROWS+cr]*second[cr+c*COLSROWS];

//time = ( REALTYPE ) ( GetTickCount( ) - st ) / 1000.;
//Print( "CPU: c-r-cr: time = " + DoubleToString( time, 3 ) + " s." );

/*
   // r-c-cr: 13.307 s 
   st = GetTickCount( );
      for( int r = 0; r < ROWS1; r ++ )
   for( int c = 0; c < COLS2; c ++ )         
         for( int cr = 0; cr < COLSROWS; cr ++ )
           third[ r * COLS2 + c ] += first[ r * COLSROWS + cr ] * second[ cr * COLS2 + c ];
   time = ( double ) ( GetTickCount( ) - st ) / 1000.;
   Print( "CPU: r-c-cr: time = " + DoubleToString( time, 3 ) + " s." );

   // c-cr-r: 17.800 s 
   st = GetTickCount( );
   for( int c = 0; c < COLS2; c ++ )         
         for( int cr = 0; cr < COLSROWS; cr ++ )
      for( int r = 0; r < ROWS1; r ++ )
           third[ r * COLS2 + c ] += first[ r * COLSROWS + cr ] * second[ cr * COLS2 + c ];           
   time = ( double ) ( GetTickCount( ) - st ) / 1000.;
   Print( "CPU: c-cr-r: time = " + DoubleToString( time, 3 ) + " s." );

   // r-cr-c: 10.265 s 
   st = GetTickCount( );
      for( int r = 0; r < ROWS1; r ++ )
         for( int cr = 0; cr < COLSROWS; cr ++ )
   for( int c = 0; c < COLS2; c ++ )         
           third[ r * COLS2 + c ] += first[ r * COLSROWS + cr ] * second[ cr * COLS2 + c ];           
   time = ( double ) ( GetTickCount( ) - st ) / 1000.;
   Print( "CPU: r-cr-c: time = " + DoubleToString( time, 3 ) + " s." );

   // cr-c-r: 17.738 s 
   st = GetTickCount( );   
         for( int cr = 0; cr < COLSROWS; cr ++ )
   for( int c = 0; c < COLS2; c ++ )         
      for( int r = 0; r < ROWS1; r ++ )
           third[ r * COLS2 + c ] += first[ r * COLSROWS + cr ] * second[ cr * COLS2 + c ];           
   time = ( double ) ( GetTickCount( ) - st ) / 1000.;
   Print( "CPU: cr-c-r: time = " + DoubleToString( time, 3 ) + " s." );

   // cr-r-c: 10.358 s 
   st = GetTickCount( );   
         for( int cr = 0; cr < COLSROWS; cr ++ )
      for( int r = 0; r < ROWS1; r ++ )
   for( int c = 0; c < COLS2; c ++ )         
           third[ r * COLS2 + c ] += first[ r * COLSROWS + cr ] * second[ cr * COLS2 + c ];           
   time = ( double ) ( GetTickCount( ) - st ) / 1000.;
   Print( "CPU: cr-r-c: time = " + DoubleToString( time, 3 ) + " s." );
*/
   return;
  }
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   initAllDataCPU();

//--- start working with non-parallel version ("bare" CPU, single core)
//--- calculate the output matrix on a single core CPU
   uint st=GetTickCount();
   mulCPUOneCore();

//--- output total calculation time
   double timeCPU=(GetTickCount()-st)/1000.;
   Print("CPUTime = "+d2s(timeCPU,3));

//--- start working with OCL
   int clCtx;             // context handle
   int clPrg;             // handle to the program on the device
   int clKrn;             // kernel handle
   int clMemIn1;          // first (input) buffer handle
   int clMemIn2;          // second (input) buffer handle
   int clMemOut;          // third (output) buffer handle

//--- start calculating the program runtime on the GPU  
//st = GetTickCount( );  

   initAllDataGPU(clCtx,clPrg,clKrn,clMemIn1,clMemIn2,clMemOut);

//--- start calculating total OCL code runtime
   st=GetTickCount();

   executeGPU(clKrn);

//--- create a buffer for reading and read the result; we will need it later
   REALTYPE buf[];
   readOutBuf(clMemOut,buf);

//--- stop calculating the total program runtime
//--- together with the time required for retrieval of data from GPU and transferring it back to RAM
   double timeGPUTotal=(GetTickCount()-st)/1000.;
   Print("OpenCL total: time = "+d2s(timeGPUTotal,3)+" sec.");

   destroyOpenCL(clCtx,clPrg,clKrn,clMemIn1,clMemIn2,clMemOut);

//--- calculate the time elapsed
   Print("CPUTime / GPUTotalTime = "+d2s(timeCPU/timeGPUTotal,3));

//--- debugging: random checks. Multiplication accuracy is checked directly on the initial and output matrices 
//--- using a few dozen examples 
   for(int i=0; i<10; i++) checkRandom(buf,ROWS1,COLS2);

   Print("________________________");
   return;
  }
//+------------------------------------------------------------------+
//| initAllDataCPU                                                   |
//+------------------------------------------------------------------+
void initAllDataCPU()
  {
//--- initialize random number generator
   MathSrand(( int) TimeLocal());
   Print("=======================================");
   Print("1st OCL martices mul:  device = "+i2s(_device)+";      ROWS1 = "+i2s(ROWS1)+"; COLSROWS = "+i2s(COLSROWS)+"; COLS2 = "+i2s(COLS2));

//--- set the required sizes of linear representations of the input and output matrices
   ArrayResize(first,ROWS1*COLSROWS);
   ArrayResize(second,COLSROWS*COLS2);
   ArrayResize(thirdGPU,ROWS1           *COLS2);
   ArrayResize(thirdCPU,ROWS1           *COLS2);

//--- generate both input matrices and initialize the output to zeros 
   genMatrices();
   ArrayInitialize( thirdCPU, 0.0 );
   ArrayInitialize( thirdGPU, 0.0 );

   return;
  }
//+------------------------------------------------------------------+
//| genMatrices                                                      |
//| lay out in row-major order, Matr[ M (rows) ][ N (columns) ]:     |
//| Matr[row][column] = buff[ row * N(columns in the matrix)+ column]|
//| generate initial matrices; this generation is not reflected      |
//| in the final runtime calculation                                 |
//| buffers are filled in row-major order!                           |
//+------------------------------------------------------------------+
void genMatrices()
  {
   for(int r=0; r<ROWS1; r++)
      for(int c=0; c<COLSROWS; c++)
         first[r*COLSROWS+c]=genVal();

//--- second change: fill the buffer in column-major order (previously filled in row-major order)
   for(int r=0; r<COLSROWS; r++)
      for(int c=0; c<COLS2; c++)
         // second[ r * COLS2 + c ] = genVal( );
         second[r+c*COLSROWS]=genVal();

   return;
  }
//+------------------------------------------------------------------+
//| genVal                                                           |
//| generate one value of the matrix element:                        |
//| uniformly distributed value lying in the range [-0.5; 0.5]       |
//+------------------------------------------------------------------+
REALTYPE genVal()
  {
   return(REALTYPE)(( MathRand()-16383.5)/32767.);
  }
//+------------------------------------------------------------------+
//| initAllDataGPU                                                   |
//+------------------------------------------------------------------+
void initAllDataGPU(int& clCtx,             // context
                    int& clPrg,             // program on the device
                    int& clKrn,             // kernel
                    int& clMemIn1,          // first (input) buffer
                    int& clMemIn2,          // second (input) buffer
                    int& clMemOut)          // third (output) buffer
  {
//--- write the kernel code to a file
   WriteCLProgram();

//--- create context, program and kernel
   clCtx = CLContextCreate( _device );
   clPrg = CLProgramCreate( clCtx, clSrc );
   clKrn = CLKernelCreate( clPrg, "matricesMul" );

//--- create all three buffers for the three matrices
//--- first matrix - input
   clMemIn1=CLBufferCreate(clCtx,ROWS1   *COLSROWS*sizeof(REALTYPE),CL_MEM_READ_WRITE);
//--- second matrix - input
   clMemIn2=CLBufferCreate(clCtx,COLSROWS*COLS2   *sizeof(REALTYPE),CL_MEM_READ_WRITE);
//--- third matrix - output
   clMemOut=CLBufferCreate(clCtx,ROWS1   *COLS2   *sizeof(REALTYPE),CL_MEM_READ_WRITE);

//--- set arguments to the kernel
   CLSetKernelArgMem(clKrn,0,clMemIn1);
   CLSetKernelArgMem(clKrn,1,clMemIn2);
   CLSetKernelArgMem(clKrn,2,clMemOut);

//--- write the generated matrices to the device buffers
   CLBufferWrite(clMemIn1,first);
   CLBufferWrite(clMemIn2,second);
   CLBufferWrite(clMemOut,thirdGPU);   // 0.0 everywhere

   return;
  }
//+------------------------------------------------------------------+
//| WriteCLProgram                                                   |
//+------------------------------------------------------------------+
void WriteCLProgram()
  {
   int h=FileOpen("matr_mul_vect.cl",FILE_WRITE|FILE_TXT|FILE_ANSI);
   FileWrite(h,clSrc);
   FileClose(h);
  }
//+------------------------------------------------------------------+
//| executeGPU                                                       |
//+------------------------------------------------------------------+
void executeGPU(int clKrn)
  {
//--- set the workspace parameters for the task and execute the OpenCL program
   uint offs[ 1 ]  = { 0 };
   uint works[ 1 ] = { ROWS1 };
   bool ex=CLExecute(clKrn,1,offs,works);
   return;
  }
//+------------------------------------------------------------------+
//| readOutBuf                                                       |
//+------------------------------------------------------------------+
void readOutBuf(int clMemOut,REALTYPE &buf[])
  {
   ArrayResize(buf,COLS2*ROWS1);
//--- buf - a copy of what is written to the buffer thirdGPU[]
   uint read=CLBufferRead(clMemOut,buf);
   Print("read = "+i2s(read)+" elements");
   return;
  }
//+------------------------------------------------------------------+
//| destroyOpenCL                                                    |
//+------------------------------------------------------------------+
void destroyOpenCL(int clCtx,int clPrg,int clKrn,int clMemIn1,int clMemIn2,int clMemOut)
  {
//--- destroy all that was created for calculations on the OpenCL device in reverse order
   CLBufferFree(clMemIn1);
   CLBufferFree(clMemIn2);
   CLBufferFree(clMemOut);
   CLKernelFree(clKrn);
   CLProgramFree(clPrg);
   CLContextFree(clCtx);
   return;
  }
//+------------------------------------------------------------------+
//| checkRandom                                                      |
//| Random check of calculation accuracy                             |
//+------------------------------------------------------------------+
void checkRandom(REALTYPE &buf[],int rows,int cols)
  {
   int r0 = genRnd( rows );
   int c0 = genRnd( cols );

   REALTYPE sum=0.0;
   for(int runningIdx=0; runningIdx<COLSROWS; runningIdx++)
      //sum += first[ r0 * COLSROWS + runningIdx ] * second[ runningIdx * COLS2 + c0 ];
      sum+=first[r0*COLSROWS+runningIdx]*second[runningIdx+c0*COLSROWS];

//--- element of the buffer m[]
   REALTYPE bufElement=buf[r0*COLS2+c0];

//--- element of the matrix not calculated in OpenCL
   REALTYPE CPUElement=thirdCPU[r0*COLS2+c0];

   Print("sum( "+i2s(r0)+","+i2s(c0)+" ) = "+d2s(sum,8)+
         ";    thirdCPU[ "+i2s(r0)+","+i2s(c0)+" ] = "+d2s(CPUElement,8)+
         ";    buf[ "+i2s(r0)+","+i2s(c0)+" ] = "+d2s(bufElement,8));
   return;
  }
//+------------------------------------------------------------------+
//| genRnd                                                           |
//+------------------------------------------------------------------+
int genRnd(int max)
  {
   return(int)(MathRand()/32767.*max);
  }
//+------------------------------------------------------------------+
