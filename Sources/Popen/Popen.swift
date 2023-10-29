//
//  Popen.swift
//  Popen
//
//  Created by John Holdsworth on 24/02/2023.
//  Repo: https://github.com/johnno1962/Popen
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

import Foundation

@_silgen_name("popen")
public func popen(_: UnsafePointer<CChar>,
    _: UnsafePointer<CChar>) -> UnsafeMutablePointer<FILE>!
@_silgen_name("pclose")
public func pclose(_: UnsafeMutablePointer<FILE>?) -> CInt

var openFILEStreams = 0

public protocol FILEStream {
    var streamHandle: UnsafeMutablePointer<FILE> { get }
}

open class Popen: FILEStream, Sequence, IteratorProtocol {

    /// Alternate version of system() call returning stdout as a String.
    /// Can also return a string of errors only if there is a failure status.
    /// - Parameters:
    ///   - cmd: Command to execute
    ///   - errors: Switch between returning String on sucess or failure.
    /// - Returns: Output of command or errors on failure if errors is true.
    open class func system(_ cmd: String, errors: Bool = false) -> String? {
        let cmd = cmd + (errors ? " 2>&1" : "")
        guard let outfp = Popen(cmd: cmd) else {
            return "popen(\"\(cmd)\") failed."
        }
        let output = outfp.readAll()
        return outfp.terminatedOK() != errors ? output : nil
    }

    open var streamHandle: UnsafeMutablePointer<FILE>
    open var exitStatus: CInt?

    public init?(cmd: String, mode: Fopen.FILEMode = .read) {
        guard let handle = popen(cmd, mode.rawValue) else {
            return nil
        }
        streamHandle = handle
        openFILEStreams += 1
    }

    open func terminatedOK() -> Bool {
        exitStatus = pclose(streamHandle)
        return exitStatus! >> 8 == EXIT_SUCCESS
    }

    deinit {
        if exitStatus == nil {
            _ = terminatedOK()
        }
        openFILEStreams -= 1
    }
}

extension UnsafeMutablePointer: FILEStream,
    Sequence, IteratorProtocol where Pointee == FILE {
    public var streamHandle: UnsafeMutablePointer<FILE> { return self }
}

// Basic extensions on UnsafeMutablePointer<FILE> 
// and Popen to read the output of a shell command
// line by line. In conjuntion with popen() this is
// useful as Task/FileHandle does not provide a
// convenient way of reading an individual line.
extension FILEStream {

    public func next() -> String? {
        return readLine() // ** No longer includes tailing newline **
    }

    public func readLine(strippingNewline: Bool = true) -> String? {
        var bufferSize = 10_000, offset = 0
        var buffer = [CChar](repeating: 0, count: bufferSize)

        while let line = fgets(&buffer[offset],
            CInt(buffer.count-offset), streamHandle) {
            offset += strlen(line)
            if buffer[offset-1] == UInt8(ascii: "\n") {
                if strippingNewline {
                    buffer[offset-1] = 0
                }
                return String(cString: buffer)
            }

            bufferSize *= 2
            var grown = [CChar](repeating: 0, count: bufferSize)
            strcpy(&grown, buffer)
            buffer = grown
        }

        return offset > 0 ? String(cString: buffer) : nil
    }

    public func readAll(close: Bool = false) -> String {
        return streamHandle.joined(separator: "\n") + "\n"
    }

    @discardableResult
    public func print(_ items: Any..., separator: String = " ",
                      terminator: String = "\n") -> CInt {
        return fputs(items.map { "\($0)" }.joined(
            separator: separator)+terminator, streamHandle)
    }

    public func write(data: Data) -> Int {
        return withUnsafeBytes(of: data) { buffer in
            fwrite(buffer.baseAddress, 1, buffer.count, streamHandle)
        }
    }

    @discardableResult
    public func flush() -> CInt {
        return fflush(streamHandle)
    }
}
