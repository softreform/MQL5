//+------------------------------------------------------------------+
//|                                                OpenCL_Sample.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//--- display the window of input parameters at the script start
#property script_show_inputs
//+------------------------------------------------------------------+
//| Enumeration for paint color selection                            |
//+------------------------------------------------------------------+
enum rgb_color
  {
   red,
   green,
   blue
  };
//--- input parameters
input float     InpXStart=-21.0f; // Start along the X-axis
input float     InpYStart=-21.0f; // Start along the Y-axis
input float     InpXStep=0.1f;    // Step along the X-axis
input float     InpYStep=0.1f;    // Step along the Y-axis
input float     InpXFinish=21.0f; // End along the X-axis
input float     InpYFinish=21.0f; // End along the Y-axis
input rgb_color InpColor=green;   // Paint color
//--- code of functions for OpenCL
const string cl_src=
                    "__kernel void Func(float x_start,                     \r\n"
                    "                   float y_start,                     \r\n"
                    "                   float x_step,                      \r\n"
                    "                   float y_step,                      \r\n"
                    "                   __global float *out)               \r\n"
                    "{                                                     \r\n"
                    "  uint  i = get_global_id(0);                         \r\n"
                    "  uint  j = get_global_id(1);                         \r\n"
                    "  uint  w = get_global_size(1);                       \r\n"
                    "  float x = x_start+i*x_step;                         \r\n"
                    "  float y = y_start+j*y_step;                         \r\n"
                    "                                                      \r\n"
                    "  float a;                                            \r\n"
                    "  if(y!=0) a = x/y;                                   \r\n"
                    "  else     a = (float)0xFFFFFF;                       \r\n"
                    "                                                      \r\n"
                    "  out[i*w+j] = pow(sin(pow(x,2)+pow(y,2)+atan(a)),2); \r\n"
                    "}                                                     \r\n"
                    "                                                      \r\n"
                    "__kernel void Grad(float min,                         \r\n"
                    "                   float dif,                         \r\n"
                    "                   uint c1,                           \r\n"
                    "                   uint c2,                           \r\n"
                    "                   __global float *in,                \r\n"
                    "                   __global uint *out)                \r\n"
                    "{                                                     \r\n"
                    "  uint i = get_global_id(0);                          \r\n"
                    "  uint x = round(255*(in[i]-min)/dif);                \r\n"
                    "  out[i] = c1*(x/16)+c2*(x%16);                       \r\n"
                    "}                                                     \r\n";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
     Print("TERMINAL_OPENCL_SUPPORT = ",TerminalInfoInteger(TERMINAL_OPENCL_SUPPORT));
   
   int cl_ctx; 
//--- initialize OpenCL context 
   if((cl_ctx=CLContextCreate(CL_USE_GPU_ONLY))==INVALID_HANDLE) 
     { 
      Print("OpenCL not found"); 
      return; 
     } 
//--- Display general information about OpenCL device 
   Print("OpenCL type: ",EnumToString((ENUM_CL_DEVICE_TYPE)CLGetInfoInteger(cl_ctx,CL_DEVICE_TYPE))); 
   Print("OpenCL vendor ID: ",CLGetInfoInteger(cl_ctx,CL_DEVICE_VENDOR_ID)); 
   Print("OpenCL units: ",CLGetInfoInteger(cl_ctx,CL_DEVICE_MAX_COMPUTE_UNITS)); 
   Print("OpenCL freq: ",CLGetInfoInteger(cl_ctx,CL_DEVICE_MAX_CLOCK_FREQUENCY)," MHz"); 
   Print("OpenCL global mem: ",CLGetInfoInteger(cl_ctx,CL_DEVICE_GLOBAL_MEM_SIZE)," bytes"); 
   Print("OpenCL local mem: ",CLGetInfoInteger(cl_ctx,CL_DEVICE_LOCAL_MEM_SIZE)," bytes"); 
//--- constants for painting the set with the required color
   uint const_1=0;
   uint const_2=0;
//--- determine values of the constants according to the paint color
   PrepareColorConstants(InpColor,const_1,const_2);
//--- determine the number of points for calculation
   uint w=(uint)((InpXFinish-InpXStart)/InpXStep);
   uint h=(uint)((InpYFinish-InpYStart)/InpYStep);
   uint size=w*h;
//--- prepare arrays for calculation of values
   float values1[];
   float values2[];
   uint  colors1[];
   uint  colors2[];
//--- allocate memory for the arrays
   ArrayResize(values1,size);
   ArrayResize(colors1,size);
   ArrayResize(values2,size);
   ArrayResize(colors2,size);
//--- calculation without OpenCL
   Print("\nCalculations without OpenCL:");
   WithoutOpenCL(values1,colors1,w,h,size,const_1,const_2);
//--- calculations with OpenCL
   Print("\nCalculations with OpenCL:");
   WithOpenCL(values2,colors2,w,h,size,const_1,const_2);
//--- create a graphical label for displaying results
//--- name of the graphical label
   string obj_name="OpenCL_"+IntegerToString(ChartID());
//--- resource name
   string res_name="BmpLbl_"+IntegerToString(ChartID());
//--- creating the graphical label
   ObjectCreate(0,obj_name,OBJ_BITMAP_LABEL,0,0,0);
   ObjectSetInteger(0,obj_name,OBJPROP_XDISTANCE,0);
   ObjectSetInteger(0,obj_name,OBJPROP_YDISTANCE,0);
   ResourceCreate(res_name,colors1,w,h,0,0,w,COLOR_FORMAT_XRGB_NOALPHA);
   ObjectSetString(0,obj_name,OBJPROP_BMPFILE,"::"+res_name);
//--- redraw the chart
   ChartRedraw();
//--- wait for 10 seconds
   Sleep(10000);
//--- delete the object
   ObjectDelete(0,obj_name);
  }
//+------------------------------------------------------------------+
//| Calculations without using OpenCL                                |
//+------------------------------------------------------------------+
void WithoutOpenCL(float &values[],uint &colors[],const uint w,const uint h,
                   const uint size,const uint const_1,const uint const_2)
  {
//--- store the calculation start time
   uint x=GetTickCount();
//--- calculation of function values
   for(uint i=0;i<h;i++)
      for(uint j=0;j<w;j++)
         values[i*w+j]=Func(InpXStart+i*InpXStep,InpYStart+j*InpYStep);
//--- print the function calculation time
   Print("Calculation of function values = "+IntegerToString(GetTickCount()-x)+" ms");
//--- determine the minimum value and the difference between 
//--- the minimum and maximum values of points in the set
   float min,dif;
   GetMinAndDifference(values,size,min,dif);
//--- store the calculation start time
   x=GetTickCount();
//--- calculation of paint colors for the set
   uint a;
   for(uint i=0;i<size;i++)
     {
      a=(uint)MathRound(255*(values[i]-min)/dif);
      colors[i]=const_1*(a/16)+const_2*(a%16);
     }
//--- print the paint color calculation time
   Print("Calculation of paint colors = "+IntegerToString(GetTickCount()-x)+" ms");
  }
//+------------------------------------------------------------------+
//| Calculations using OpenCL                                        |
//+------------------------------------------------------------------+
void WithOpenCL(float &values[],uint &colors[],const uint w,const uint h,
                const uint size,const uint const_1,const uint const_2)
  {
//--- variables for using OpenCL
   int cl_ctx;
   int cl_prg;
   int cl_krn_1;
   int cl_krn_2;
   int cl_mem_1;
   int cl_mem_2;
//--- create context for OpenCL (selection of device)
   if((cl_ctx=CLContextCreate(CL_USE_ANY))==INVALID_HANDLE)
     {
      Print("OpenCL not found");
      return;
     }
//--- create a program based on the code in the cl_src line
   if((cl_prg=CLProgramCreate(cl_ctx,cl_src))==INVALID_HANDLE)
     {
      CLContextFree(cl_ctx);
      Print("OpenCL program create failed");
      return;
     }
//--- create a kernel for calculation of values of the function of two variables
   if((cl_krn_1=CLKernelCreate(cl_prg,"Func"))==INVALID_HANDLE)
     {
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL kernel_1 create failed");
      return;
     }
//--- kernel for painting points of the set in the plane
   if((cl_krn_2=CLKernelCreate(cl_prg,"Grad"))==INVALID_HANDLE)
     {
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL kernel_2 create failed");
      return;
     }
//--- OpenCL buffer for function values
   if((cl_mem_1=CLBufferCreate(cl_ctx,size*sizeof(float),CL_MEM_READ_WRITE))==INVALID_HANDLE)
     {
      CLKernelFree(cl_krn_2);
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
     }
//--- OpenCL buffer for point colors
   if((cl_mem_2=CLBufferCreate(cl_ctx,size*sizeof(uint),CL_MEM_READ_WRITE))==INVALID_HANDLE)
     {
      CLBufferFree(cl_mem_1);
      CLKernelFree(cl_krn_2);
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
     }
//--- store the calculation start time
   uint x=GetTickCount();
//--- array sets indices at which the calculation will start  
   uint offset[2]={0,0};
//--- array sets limits up to which the calculation will be performed
   uint work[2];
   work[0]=h;
   work[1]=w;
//--- calculation of function values
//--- pass the values to the kernel
   CLSetKernelArg(cl_krn_1,0,InpXStart);
   CLSetKernelArg(cl_krn_1,1,InpYStart);
   CLSetKernelArg(cl_krn_1,2,InpXStep);
   CLSetKernelArg(cl_krn_1,3,InpYStep);
   CLSetKernelArgMem(cl_krn_1,4,cl_mem_1);
//--- start the execution of the kernel
   CLExecute(cl_krn_1,2,offset,work);
//--- read the obtained values to the array
   CLBufferRead(cl_mem_1,values);
//--- print the function calculation time
   Print("Calculation of function values = "+IntegerToString(GetTickCount()-x)+" ms");
//--- determine the minimum value and the difference between 
//--- the minimum and maximum values of points in the set
   float min,dif;
   GetMinAndDifference(values,size,min,dif);
//--- store the calculation start time
   x=GetTickCount();
//--- set the calculation limits
   uint offset2[1]={0};
   uint work2[1];
   work2[0]=size;
//--- calculation of paint colors for the set
//--- pass the values to the kernel
   CLSetKernelArg(cl_krn_2,0,min);
   CLSetKernelArg(cl_krn_2,1,dif);
   CLSetKernelArg(cl_krn_2,2,const_1);
   CLSetKernelArg(cl_krn_2,3,const_2);
   CLSetKernelArgMem(cl_krn_2,4,cl_mem_1);
   CLSetKernelArgMem(cl_krn_2,5,cl_mem_2);
//--- start the execution of the kernel
   CLExecute(cl_krn_2,1,offset2,work2);
//--- read the obtained values to the array
   CLBufferRead(cl_mem_2,colors);
//--- print the paint color calculation time
   Print("Calculation of paint colors = "+IntegerToString(GetTickCount()-x)+" ms");
//--- delete OpenCL objects
   CLBufferFree(cl_mem_1);
   CLBufferFree(cl_mem_2);
   CLKernelFree(cl_krn_1);
   CLKernelFree(cl_krn_2);
   CLProgramFree(cl_prg);
   CLContextFree(cl_ctx);
  }
//+------------------------------------------------------------------+
//| Function of two variables                                        |
//+------------------------------------------------------------------+
float Func(const float x,const float y)
  {
//--- prepare the arctangent argument
   float arg;
   if(y!=0) arg=x/y;
   else     arg=(float)0xFFFFFF;
//--- calculate the function and return the result
   return((float)MathPow(MathSin(MathPow(x,2)+MathPow(y,2)+MathArctan(arg)),2));
  }
//+------------------------------------------------------------------+
//| Function for determining values of constants according to color  |
//+------------------------------------------------------------------+
void PrepareColorConstants(const rgb_color clr,uint &const_1,uint &const_2)
  {
//--- determine values of constants
   switch(InpColor)
     {
      case red:
         const_1=1048576;
         const_2=65536;
         break;
      case green:
         const_1=4096;
         const_2=256;
         break;
      case blue:
         const_1=16;
         const_2=1;
         break;
     }
  }
//+----------------------------------------------------------------------+
//| Function for determining the minimum value and the difference between|
//| the minimum and maximum values of array                              |
//+----------------------------------------------------------------------+
void GetMinAndDifference(const float &arr[],const int size,float &min,float &dif)
  {
//--- find the maximum and minimum values of the sample
   dif=-FLT_MAX; // serves as maximum in the loop
   min=FLT_MAX;  // minimum
   for(int i=0;i<size;i++)
     {
      //--- find the maximum
      if(arr[i]>dif)
         dif=arr[i];
      //--- find the minimum
      if(arr[i]<min)
         min=arr[i];
     }
//--- determine the difference
   dif=dif-min;
  }
//+------------------------------------------------------------------+
