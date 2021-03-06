//+------------------------------------------------------------------+
//|                                                   OCLDefines.mqh |
//|                                  Copyright 2018, Serhii Shevchuk |
//|                           https://www.mql5.com/en/users/decanium |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Serhii Shevchuk"
#property link      "https://www.mql5.com/en/users/decanium"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- set execution error
#define SET_ERR(c) do {m_last_error.function = __FUNCTION__; \
      m_last_error.line =__LINE__; \
      m_last_error.code=::GetLastError(); m_last_error.comment=c;} while(0)
//--- set execution error with passing the function name and the line index via the parameter
#define SET_ERRx(c,f,l) do {m_last_error.function = f; m_last_error.line = l; \
      m_last_error.code=::GetLastError(); m_last_error.comment=c;} while(0)
//--- set the custom error
#define SET_UERR(err,c) do {m_last_error.function = __FUNCTION__; \
      m_last_error.line =__LINE__; \
      m_last_error.code=ERR_USER_ERROR_FIRST+err; m_last_error.comment=c;} while(0)
//--- set the custom error with passing the function name and the line index via the parameter
#define SET_UERRx(err,c,f,l) do {m_last_error.function = f; m_last_error.line = l; \
      m_last_error.code=ERR_USER_ERROR_FIRST+err; m_last_error.comment=c;} while(0)
//--- call the functions for working with OpenCL
#define _BufferFromArray(buffer_index,data,data_array_offset,data_array_count,flags) \
      if(BufferFromArray(buffer_index,data,data_array_offset,data_array_count,flags,__FUNCTION__,__LINE__)==false) return false
#define _BufferCreate(buffer_index,size_in_bytes,flags) \
      if(BufferCreate(buffer_index,size_in_bytes,flags,__FUNCTION__,__LINE__)==false) return false
#define _BufferRead(buffer_index,data,cl_buffer_offset,data_array_offset,data_array_count) \
      if(BufferRead(buffer_index,data,cl_buffer_offset,data_array_offset,data_array_count,__FUNCTION__,__LINE__)==false) return false
#define _BufferWrite(buffer_index,data,cl_buffer_offset,data_array_offset,data_array_count) \
      if(BufferWrite(buffer_index,data,cl_buffer_offset,data_array_offset,data_array_count,__FUNCTION__,__LINE__)==false) return false
#define _Execute(kernel_index,work_dim,work_offset,work_size) \
      if(Execute(kernel_index,work_dim,work_offset,work_size,__FUNCTION__,__LINE__)==false) return false
#define _SetArgument(kernel_index,arg_index,value) \
      if(SetArgument(kernel_index,arg_index,value,__FUNCTION__,__LINE__)==false) return false
#define _SetArgumentBuffer(kernel_index,arg_index,buffer_index) \
      if(SetArgumentBuffer(kernel_index,arg_index,buffer_index,__FUNCTION__,__LINE__)==false) return false
#define _KernelCreate(k,src) \
      if(KernelCreate(k,src,__FUNCTION__,__LINE__)==false) break

//--- Custom errors  
#define UERR_NONE                0     // No error
#define UERR_NO_OCL              1     // COpenCL object does not exist
#define UERR_GET_MEMORY_SIZE     2     // Failed to get memory size
#define UERR_KERNEL_CREATE       3     // Failed to create kernel
#define UERR_SET_BUF_COUNT       4     // Failed to set the number of buffers
#define UERR_DOUBLE_NOT_SUPP     5     // double not supported
#define UERR_BUFFER_CREATE       6     // Failed to create buffer
#define UERR_BUFFER_FROM_ARRAY   7     // Failed to create buffer from array
#define UERR_BUFFER_READ         8     // Failed to read buffer
#define UERR_BUFFER_WRITE        9     // Failed to write buffer
#define UERR_SET_ARGUMENT        10    // Failed to set argument
#define UERR_SET_ARGUMENT_BUFFER 11    // Failed to set buffer as argument
#define UERR_EXECUTE             12    // Kernel execution error
#define UERR_NO_ENOUGH_MEM       13    // No free memory

//--- Tester errors
#define UERR_TESTER_ERROR_FIRST  256
#define SET_UERRt(err,c)         SET_UERR(UERR_TESTER_ERROR_FIRST+err,c)
//+------------------------------------------------------------------+
