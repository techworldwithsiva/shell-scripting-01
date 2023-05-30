### Conditions

Conditions are used to take a decision. Usually we use if. A general syntax is

```
if [ expression ]
then
    these statements run above expression is true
else
    these statements run above expression is true
fi
```

### Exit Status

Usually in Linux, script won't stop by default even it face error. It is our responsibility to check the previous command is success or not.

0        --> Success code <br/>
1-127 --> Failure