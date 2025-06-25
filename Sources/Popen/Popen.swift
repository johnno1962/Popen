//
//  Popen.swift
//  Popen
//
//  Created by John Holdsworth on 24/02/2023.
//  Repo: https://github.com/johnno1962/Popen
//  $Id: //depot/Popen/Sources/Popen/Popen.swift#9 $
//
//  See: https://c-for-dummies.com/blog/?p=1418
//
//  Re-surface the popen() and pclose() functions
//  which can be ued to run shell commands on macOS
//  (and in the simulator). Open for read to process
//  output of command, write to send std input to the
//  command. The command is parsed and run by the shell.
//
//  NOTE since 2.0.0 using a PopenStream as a Sequnce, the
//  Strings returned no longer include the trailing newline.
//  Added a class wrapper to look after calling p/fclose().
//

#if DEBUG || !DEBUG_ONLY
import Foundation

@_silgen_name("popen")
public func popen(_: UnsafePointer<CChar>,
    _: UnsafePointer<CChar>) -> UnsafeMutablePointer<FILE>!
@_silgen_name("pclose")
public func pclose(_: UnsafeMutablePointer<FILE>?) -> CInt

open class Popen: FILEStream, Sequence, IteratorProtocol {
    public static var openedFILEStreams = 0, closedFILEStreams = 0
    public static var openFILEStreams: Int {
        return openedFILEStreams - closedFILEStreams }
    public static var initialLineBufferSize = 10_000
    public static var shellCommand = "/bin/bash"

    /// Execute a shell command
    /// - Parameters:
    ///   - cmd: Command to execute
    ///   - shell: Shell to use for the command.
    /// - Returns: true if command exited without error.
    open class func shell(cmd: String, shell: String = shellCommand) -> Bool {
        guard let stdin = Popen(cmd: shell, mode: .write) else {
            return false
        }
        stdin.print(cmd)
        return stdin.terminatedOK()
    }

    /// Alternate version of system() call returning stdout as a String.
    /// Can also return a string of errors only if there is a failure status.
    /// - Parameters:
    ///   - cmd: Command to execute
    ///   - errors: Switch between returning String on sucess or failure.
    /// - Returns: Output of command or errors on failure if errors is true.
    open class func system(_ cmd: String, errors: Bool? = false) -> String? {
        let cmd = cmd + (errors != false ? " 2>&1" : "")
        guard let outfp = Popen(cmd: cmd) else {
            return "popen(\"\(cmd)\") failed."
        }
        let output = outfp.readAll()
        return outfp.terminatedOK() != errors ? output : nil
    }

    #if os(macOS)
    /// Alternate version of system() call returning stdout as a String.
    /// Can also return a string of errors only if there is a failure status.
    /// - Parameters:
    ///   - exec: Binary to execute
    ///   - arguments: Arguments to pass to executable
    ///   - errors: Switch between returning String on sucess or failure.
    /// - Returns: Output of command or errors on failure if errors is true.
    open class func task(exec: String, arguments: [String] = [],
                         cd: String = "/tmp", errors: Bool? = false) -> String? {
        let task = Topen(exec: exec, arguments: arguments, cd: cd)
        let output = task.readAll()
        return task.terminatedOK() != errors ? output : nil
    }
    #endif

    open var fileStream: UnsafeMutablePointer<FILE>
    open var exitStatus: CInt?

    public init(stream: UnsafeMutablePointer<FILE>) {
        Self.openedFILEStreams += 1
        fileStream = stream
    }

    public convenience init?(cmd: String, mode: Fopen.FILEMode = .read) {
        guard let stream = popen(cmd, mode.mode) else {
            return nil
        }
        self.init(stream: stream)
    }

    open func terminatedOK() -> Bool {
        if exitStatus == nil {
            exitStatus = pclose(fileStream)
        }
        return exitStatus == EXIT_SUCCESS
    }

    deinit {
        _ = terminatedOK()
        Self.closedFILEStreams += 1
    }
}
#endif
