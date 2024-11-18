1. Using the distroless image for smallest attack surface (https://github.com/GoogleContainerTools/distroless).  
2. The verification with 'dive' passes, it shows this:  
  
CI=true dive 0651a3be7cc0
  Using default CI config
Image Source: docker://0651a3be7cc0
Fetching image... (this can take a while for large images)
Analyzing image...
  efficiency: 99.9993 %
  wastedBytes: 613 bytes (613 B)
  userWastedPercent: 0.0012 %
Inefficient Files:
Count  Wasted Space  File Path
    2         613 B  /usr/lib/os-release
    2           0 B  /tmp
    2           0 B  /root
Results:
  PASS: highestUserWastedPercent
  SKIP: highestWastedBytes: rule disabled
  PASS: lowestEfficiency
Result:PASS [Total:3] [Passed:2] [Failed:0] [Warn:0] [Skipped:1]
