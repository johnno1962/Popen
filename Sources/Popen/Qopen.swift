//
//  Qopen.swift
//  
//  A terminatable popen() task.
//
//  Created by John Holdsworth on 25/06/2025.
//  Repo: https://github.com/johnno1962/Popen
//  $Id: //depot/Popen/Sources/Popen/Qopen.swift#3 $
//

#if DEBUG || !DEBUG_ONLY
import Foundation

open class Qopen: Popen {

    let pidStore: String

    public init?(cmd: String, mode: Fopen.FILEMode = .read) {
        pidStore = "/tmp/popen.pid.\(getpid()).\(Self.openedFILEStreams)"
        guard let stream = popen("echo $$>\(pidStore); "+cmd,
                                 mode.mode) else { return nil }
        super.init(stream: stream)
    }

    public var processID: pid_t? {
        for _ in 0..<6 {
            if let pid = (try? String(contentsOfFile: pidStore)
                .trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap({ pid_t($0) }) {
                return pid
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return nil
    }

    open func terminate(signal: CInt = SIGKILL) {
        guard let pid = processID,
            kill(pid, signal) == KERN_SUCCESS else {
            return NSLog("\(Self.self): could not signal pid: "+pidStore)
        }
    }

    deinit { unlink(pidStore) }
}
#endif
