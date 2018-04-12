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
   
   
   ## 过滤字符串中的空格
   
   ``` objc 
   NSString *string = @" 1 2 3 ";
   ```
   
   1. `stringByTrimmingCharactersInSet`
   
    ``` objc
    NSString *result1 = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    string: @"1 2 3";
    ```
  `stringByTrimmingCharactersInSet`只能去掉开头和结尾的空格，对于中间的空格无能为力。
  

  2.
  
  ``` objc
  NSArray *words = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    string = [words componentsJoinedByString:@""];
    
    string: @"123"; 
  ```  
  

  3.
  
  ```objc
 string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
 
 string: @"123"
  ```