# Popen

Bring no-frills UNIX IPC back into Swift. For example:

```
    guard let inp = Popen(cmd: "/bin/ls /tmp"),
          let out = Popen(cmd: "/usr/bin/wc", mode: .write) else {
        return XCTFail("Could not open processes")
    }
    while let line = inp.readLine() {
        out.print(line)
    }
```
Version 2.0.0 and above introduces a wrapping Swift class that
looks after calling p/fclose() when you have finished with a
process. There is also an incompatable change that reading
lines from a FILEStream as a Sequence no longer includes the 
trailing newline bringing it into line with the readLine() 
method on the grounds that it's easier to add again than 
remove it afterwards. New class Fopen() added rounding out 
this exploration of the stdio library for use in Swift.

The old version of the code above was:

```
    let inp = popen("/bin/ls /tmp", "r")
    let out = popen("/usr/bin/wc", "w")
    while let line = inp?.readLine() {
        out?.print(line)
    }
    pclose(inp)
    pclose(out)
```
Also included are lightweight wrappers for `glob` and `stat`.
