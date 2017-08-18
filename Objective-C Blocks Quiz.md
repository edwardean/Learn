### Objective-C Blocks Quiz


#### Example A

``` objc
void exampleA() {
  char a = 'A';
  ^{
    printf("%cn", a);
  }();
}
```


- This example
	* aways works
   * only works with ARC.
	* only works without ARC.
	* never works.

#### Example B

``` objc
void exampleB_addBlockToArray(NSMutableArray *array) {
  char b = 'B';
  [array addObject:^{
    printf("%cn", b);
  }];
}

void exampleB() {
  NSMutableArray *array = [NSMutableArray array];
  exampleB_addBlockToArray(array);
  void (^block)() = [array objectAtIndex:0];
  block();
}
```
- This example
	* aways works
   * only works with ARC.
	* only works without ARC.
	* never works.
	
	
#### Example C

``` objc
void exampleC_addBlockToArray(NSMutableArray *array) {
  [array addObject:^{
    printf("Cn");
  }];
}

void exampleC() {
  NSMutableArray *array = [NSMutableArray array];
  exampleC_addBlockToArray(array);
  void (^block)() = [array objectAtIndex:0];
  block();
}
```

- This example
	- aways works
   - only works with ARC.
	- only works without ARC.
	- never works.
	
	
#### Example D

``` objc
typedef void (^dBlock)();

dBlock exampleD_getBlock() {
  char d = 'D';
  return ^{
    printf("%cn", d);
  };
}

void exampleD() {
  exampleD_getBlock()();
}
```
- This example
	* aways works
   * only works with ARC.
	* only works without ARC.
	* never works.

#### Example E

``` objc
typedef void (^eBlock)();

eBlock exampleE_getBlock() {
  char e = 'E';
  void (^block)() = ^{
    printf("%cn", e);
  };
  return block;
}

void exampleE() {
  eBlock block = exampleE_getBlock();
  block();
}
```
- This example
	* aways works
   * only works with ARC.
	* only works without ARC.
	* never works.
