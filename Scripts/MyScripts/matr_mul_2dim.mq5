//+------------------------------------------------------------------+
//|                                                matr_mul_2dim.mq5 |
//+------------------------------------------------------------------+
#define ROWS1           2000        // rows in the first matrix
#define COLSROWS        2000        // columns in the first matrix = rows in the second matrix 
#define COLS2           2000        // columns in the second matrix

float first[ ROWS1  ][ COLSROWS ];  // first matrix
float second[ COLSROWS ][ COLS2 ];  // second matrix
float third[ ROWS1 ][ COLS2 ];      // product
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   MathSrand(GetTickCount());

   Print("=======================================");
   Print("ROWS1 = "+i2s(ROWS1)+"; COLSROWS = "+i2s(COLSROWS)+"; COLS2 = "+i2s(COLS2));

   genMatrices();
   ArrayInitialize(third,0.0f);

//--- execution on the CPU
   uint st1=GetTickCount();
   mul();
   double time1=(double)(GetTickCount()-st1)/1000.;
   Print("CPU: time = "+DoubleToString(time1,3)+" s.");

   return;
  }
//+------------------------------------------------------------------+
//| i2s                                                              |
//+------------------------------------------------------------------+
string i2s(int arg) { return IntegerToString(arg); }
//+------------------------------------------------------------------+
//| genMatrices                                                      |
//| generate initial matrices; this generation is not reflected      |
//| in the final runtime calculation                                 |
//+------------------------------------------------------------------+
void genMatrices()
  {
   for(int r=0; r<ROWS1; r++)
      for(int c=0; c<COLSROWS; c++)
         first[r][c]=genVal();

   for(int r=0; r<COLSROWS; r++)
      for(int c=0; c<COLS2; c++)
         second[r][c]=genVal();

   return;
  }
//+------------------------------------------------------------------+
//| genVal                                                           |
//| generate one value of the matrix element:                        |
//| uniformly distributed value lying in the range [-0.5; 0.5]       |
//+------------------------------------------------------------------+
float genVal()
  {
   return(float)(( MathRand()-16383.5)/32767.);
  }
//+------------------------------------------------------------------+
//| mul                                                              |
//| Main matrix multiplication function                              |
//+------------------------------------------------------------------+
void mul()
  {
/*
  // c-r-cr: 12.433 s 
   for( int c = 0; c < COLS2; c ++ )         
      for( int r = 0; r < ROWS1; r ++ )
         for( int cr = 0; cr < COLSROWS; cr ++ )
           third[ r ][ c ] += first[ r ][ cr ] * second[ cr ][ c ];      

  // r-c-cr: 14.259 s 
      for( int r = 0; r < ROWS1; r ++ )
   for( int c = 0; c < COLS2; c ++ )         
         for( int cr = 0; cr < COLSROWS; cr ++ )
           third[ r ][ c ] += first[ r ][ cr ] * second[ cr ][ c ];

   // c-cr-r: 18.175 s 
   for( int c = 0; c < COLS2; c ++ )         
         for( int cr = 0; cr < COLSROWS; cr ++ )
      for( int r = 0; r < ROWS1; r ++ )
           third[ r ][ c ] += first[ r ][ cr ] * second[ cr ][ c ];
*/

// r-cr-c: 10.530 s 
   for(int r=0; r<ROWS1; r++)
      for(int cr=0; cr<COLSROWS; cr++)
         for(int c=0; c<COLS2; c++)
            third[r][c]+=first[r][cr]*second[cr][c];

/*
  // cr-c-r: 18.065 s 
         for( int cr = 0; cr < COLSROWS; cr ++ )
   for( int c = 0; c < COLS2; c ++ )         
      for( int r = 0; r < ROWS1; r ++ )
           third[ r ][ c ] += first[ r ][ cr ] * second[ cr ][ c ];

  // cr-r-c: 10.561 s 
         for( int cr = 0; cr < COLSROWS; cr ++ )
      for( int r = 0; r < ROWS1; r ++ )
   for( int c = 0; c < COLS2; c ++ )         
           third[ r ][ c ] += first[ r ][ cr ] * second[ cr ][ c ];
*/
   return;
  }
//+------------------------------------------------------------------+
