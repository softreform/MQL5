//+------------------------------------------------------------------+
//|                                                      OpenCLx.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
#property version   "1.00"

//--- COpenCL class
#include <OpenCL/OpenCL.mqh>
//--- IDs of kernels and buffers, OpenCL source codes
#include "OCLInc.mqh"
//--- statistics class
#include "OCLStat.mqh"
//--- macros
#include "OCLDefines.mqh"
//--- error structure
struct STR_ERROR
  {
   int               code;       // code 
   string            comment;    // comment 
   string            function;   // function the error has occurred in
   int               line;       // line the error has occurred in
  };
//--- initialization mode
enum ENUM_INIT_MODE
  {
   i_MODE_TESTER=0,  // tester
   i_MODE_OPTIMIZER  // optimizer
  };
//+------------------------------------------------------------------+
//| OpenCL Extended                                                  |
//+------------------------------------------------------------------+
class COpenCLx : public COpenCL
  {
private:
   COpenCL          *ocl;
public:
                     COpenCLx();
                    ~COpenCLx();
   STR_ERROR         m_last_error;  // last error structure
   COCLStat          m_stat;        // OpenCL statistics                    
   //--- working with buffers
   bool              BufferCreate(const ENUM_BUFFERS buffer_index,const uint size_in_bytes,const uint flags,const string function,const int line);
   template<typename T>
   bool              BufferFromArray(const ENUM_BUFFERS buffer_index,T &data[],const uint data_array_offset,const uint data_array_count,const uint flags,const string function,const int line);
   template<typename T>
   bool              BufferRead(const ENUM_BUFFERS buffer_index,T &data[],const uint cl_buffer_offset,const uint data_array_offset,const uint data_array_count,const string function,const int line);
   template<typename T>
   bool              BufferWrite(const ENUM_BUFFERS buffer_index,T &data[],const uint cl_buffer_offset,const uint data_array_offset,const uint data_array_count,const string function,const int line);
   //--- set the arguments
   template<typename T>
   bool              SetArgument(const ENUM_KERNELS kernel_index,const int arg_index,T value,const string function,const int line);
   bool              SetArgumentBuffer(const ENUM_KERNELS kernel_index,const int arg_index,const ENUM_BUFFERS buffer_index,const string function,const int line);
   //--- work with kernel
   bool              KernelCreate(const ENUM_KERNELS kernel_index,const string kernel_name,const string function,const int line);
   bool              Execute(const ENUM_KERNELS kernel_index,const int work_dim,const uint &work_offset[],const uint &work_size[],const string function,const int line);
   //---
   bool              Init(ENUM_INIT_MODE mode);
   void              Deinit(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
COpenCLx::COpenCLx() : ocl(NULL)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
COpenCLx::~COpenCLx()
  {
  }
//+------------------------------------------------------------------+
//| KernelCreate                                                     |
//+------------------------------------------------------------------+
bool COpenCLx::KernelCreate(const ENUM_KERNELS kernel_index,const string kernel_name,const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- Launch the kernel execution
   ::ResetLastError();
   if(!ocl.KernelCreate(kernel_index,kernel_name))
     {
      string comment="Failed to create kernel "+EnumToString(kernel_index)+", name \""+kernel_name+"\"";
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_KERNEL_CREATE,comment,function,line);
      return(false);
     }
//---
   return true;
  }
//+------------------------------------------------------------------+
//| Execute                                                          |
//+------------------------------------------------------------------+
bool COpenCLx::Execute(const ENUM_KERNELS kernel_index,const int work_dim,const uint &work_offset[],const uint &work_size[],const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- Launch the kernel execution
   ::ResetLastError();
   if(!ocl.Execute(kernel_index,work_dim,work_offset,work_size))
     {
      string comment="Failed to launch kernel "+EnumToString(kernel_index);
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_EXECUTE,comment,function,line);
      return(false);
     }
//---
   return true;
  }
//+------------------------------------------------------------------+
//| BufferCreate                                                     |
//+------------------------------------------------------------------+
bool COpenCLx::BufferCreate(const ENUM_BUFFERS buffer_index,const uint size_in_bytes,const uint flags,const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- account and check free memory
   if((m_stat.gpu_mem_usage+=size_in_bytes)==false)
     {
      CMemsize cmem=m_stat.gpu_mem_usage.Comp(size_in_bytes);
      SET_UERRx(UERR_NO_ENOUGH_MEM,"No free GPU memory. Insufficient "+cmem.ToStr(),function,line);
      return false;
     }
//--- create the buffer
   ::ResetLastError();
   if(ocl.BufferCreate(buffer_index,size_in_bytes,flags)==false)
     {
      string comment="Failed to create buffer "+EnumToString(buffer_index);
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_BUFFER_CREATE,comment,function,line);
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| BufferFromArray                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool COpenCLx::BufferFromArray(const ENUM_BUFFERS buffer_index,T &data[],const uint data_array_offset,const uint data_array_count,const uint flags,const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- account and check free memory
   uint sz=sizeof(T)*data_array_count;
   if((m_stat.gpu_mem_usage+=sz)==false)
     {
      CMemsize cmem=m_stat.gpu_mem_usage.Comp(sz);
      SET_UERRx(UERR_NO_ENOUGH_MEM,"No free GPU memory. Insufficient "+cmem.ToStr(),function,line);
      return false;
     }
//--- create the buffer from the array
   ::ResetLastError();
   if(!ocl.BufferFromArray(buffer_index,data,data_array_offset,data_array_count,flags))
     {
      string comment="Failed to create buffer "+EnumToString(buffer_index);
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_BUFFER_FROM_ARRAY,comment,function,line);
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| BufferRead                                                       |
//+------------------------------------------------------------------+
template<typename T>
bool COpenCLx::BufferRead(const ENUM_BUFFERS buffer_index,T &data[],const uint cl_buffer_offset,const uint data_array_offset,const uint data_array_count,const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- read the buffer
   ::ResetLastError();
   if(!ocl.BufferRead(buffer_index,data,cl_buffer_offset,data_array_offset,data_array_count))
     {
      string comment="Failed to read buffer "+EnumToString(buffer_index);
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_BUFFER_READ,comment,function,line);
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| BufferWrite                                                      |
//+------------------------------------------------------------------+
template<typename T>
bool COpenCLx::BufferWrite(const ENUM_BUFFERS buffer_index,T &data[],const uint cl_buffer_offset,const uint data_array_offset,const uint data_array_count,const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- write the buffer
   ::ResetLastError();
   if(!ocl.BufferWrite(buffer_index,data,cl_buffer_offset,data_array_offset,data_array_count))
     {
      string comment="Failed to write buffer "+EnumToString(buffer_index);
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_BUFFER_WRITE,comment,function,line);
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| SetArgument                                                      |
//+------------------------------------------------------------------+
template<typename T>
bool COpenCLx::SetArgument(const ENUM_KERNELS kernel_index,const int arg_index,T value,const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- set the argument
   ::ResetLastError();
   if(!ocl.SetArgument(kernel_index,arg_index,value))
     {
      string comment="Failed to set argument "+IntegerToString(arg_index)+
                     " for kernel "+EnumToString(kernel_index);
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_SET_ARGUMENT,comment,function,line);
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| SetArgumentBuffer                                                |
//+------------------------------------------------------------------+
bool COpenCLx::SetArgumentBuffer(const ENUM_KERNELS kernel_index,const int arg_index,const ENUM_BUFFERS buffer_index,const string function,const int line)
  {
   if(ocl==NULL)
     {
      SET_UERRx(UERR_NO_OCL,"OpenCL object does not exist",function,line);
      return false;
     }
//--- set the buffer as an argument
   ::ResetLastError();
   if(!ocl.SetArgumentBuffer(kernel_index,arg_index,buffer_index))
     {
      string comment="Failed to set buffer "+EnumToString(buffer_index)+
                     " as argument "+IntegerToString(arg_index)+
                     " for kernel "+EnumToString(kernel_index);
      SET_ERRx(comment,function,line);
      if(!m_last_error.code)
         SET_UERRx(UERR_SET_ARGUMENT_BUFFER,comment,function,line);
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
bool COpenCLx::Init(ENUM_INIT_MODE mode)
  {
   if(ocl) Deinit();
//--- create COpenCL class object
   ocl=new COpenCL;
   while(!IsStopped())
     {
      //--- initialize OpenCL
      ::ResetLastError();
      if(!ocl.Initialize(cl_tester,true))
        {
         SET_ERR("OpenCL initialization error");
         break;
        }  
      //--- check support for working with double
      if(!ocl.SupportDouble())
        {
         SET_UERR(UERR_DOUBLE_NOT_SUPP,"Working with double (cl_khr_fp64) not supported by device");
         break;
        }  
      //--- set the number of kernels
      if(!ocl.SetKernelsCount(OCL_KERNELS_COUNT))
         break;
      //--- create the kernels         
      if(mode==i_MODE_TESTER)
        {
         _KernelCreate(k_FIND_PATTERNS,"find_patterns");
         _KernelCreate(k_ARRAY_FILL,"array_fill");
         _KernelCreate(k_ORDER_TO_M1,"order_to_M1");
         _KernelCreate(k_TESTER_STEP,"tester_step");
        }
      else if(mode==i_MODE_OPTIMIZER)
        {
         _KernelCreate(k_ARRAY_FILL,"array_fill");
         _KernelCreate(k_TESTER_OPT_PREPARE,"tester_opt_prepare");
         _KernelCreate(k_TESTER_OPT_STEP,"tester_opt_step");
         _KernelCreate(k_FIND_PATTERNS_OPT,"find_patterns_opt");
        }
      else
         break;  
      //--- create the buffers
      if(!ocl.SetBuffersCount(OCL_BUFFERS_COUNT))
        {
         SET_UERR(UERR_SET_BUF_COUNT,"Failed to create buffers");
         break;
        }  
      //--- get RAM size          
      long gpu_mem_size;
      if(ocl.GetGlobalMemorySize(gpu_mem_size)==false)
        {
         SET_UERR(UERR_GET_MEMORY_SIZE,"Failed to get RAM size");
         break;
        }
      m_stat.gpu_mem_size.Set(gpu_mem_size);
      m_stat.gpu_mem_usage.Max(gpu_mem_size);
      return true;
     }
   Deinit();
   return false;
  }
//+------------------------------------------------------------------+
//| Deinit                                                           |
//+------------------------------------------------------------------+
void COpenCLx::Deinit()
  {
   if(ocl!=NULL)
     {
      //--- remove OpenCL objects
      ocl.Shutdown();
      delete ocl;
      ocl=NULL;
     }
  }
//+------------------------------------------------------------------+
