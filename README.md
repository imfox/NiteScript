# NiteScript
interpreter

### code
```
a = 10 b = 20 c = 30
print(a + b + c)

fn test1(pa){
    // global func
    dim fn global_func() {
        print("global_func")
    }

    // local func
    fn local_func() {
        dim globalValue = "globalValue";
        print("local func")
    }

    local_func()
}

if nil?1:0 {
    print("nil is false")
}

print("globalValue before:", globalValue)

test1()

print("globalValue after:", globalValue)

print("local_func", typeof(local_func));

global_func();

```

### result
```
> 60
> globalValue before:	nil
> local func
> globalValue after:	globalValue
> local_func is:	nil
> global_func
```