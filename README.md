# Popen

Bring no-frills UNIX IPC back into Swift. For example:

```
    let inp = popen("/bin/ls /tmp", "r")
    let out = popen("/usr/bin/wc", "w")
    while let line = inp?.readLine() {
        out?.print(line)
    }
    pclose(inp)
    pclose(out)
```
