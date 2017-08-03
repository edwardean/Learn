## NSInvocation
   - getReturnValue:
   
  1.
  
   ```
   void *result;
   [invocation getReturnValue:&result];
   id returnValue = (__bridge id)result;
   ```
   
   2.
   
   ```
   __unsafe_unretained id result = nil;
   [invocation getReturnValue:&result];
   
   ```
   
   3.
   
   ```
   __autoreleasing id returnObj;
	[invocation getReturnValue:&returnObj];
   ```