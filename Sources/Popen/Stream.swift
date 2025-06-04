//
//  Stream.swift
//
//  Swifty operations on a stdio FILE stream.
//
//  Created by John Holdsworth on 03/06/2024.
//  Repo: https://github.com/johnno1962/Popen
//  $Id: //depot/Popen/Sources/Popen/Stream.swift#4 $
//

#if DEBUG || !DEBUG_ONLY
import Foundation

public protocol FILEStream {
    var fileStream: UnsafeMutablePointer<FILE> { get }
}

extension UnsafeMutablePointer: FILEStream,
    Swift.Sequence, Swift.IteratorProtocol where Pointee == FILE {
    public typealias Element = String
    public var fileStream: Self { return self }
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
        var buffer = [CChar](repeating: 0, count: Popen.initialLineBufferSize)
        var offset = 0

        while let line = fgets(&buffer[offset],
            CInt(buffer.count-offset), fileStream) {
            offset += strlen(line)
            if offset > 0 && buffer[offset-1] == UInt8(ascii: "\n") {
                if strippingNewline {
                    buffer[offset-1] = 0
                }
                return String(cString: buffer)
            }

            var grown = [CChar](repeating: 0, count: buffer.count*2)
            strcpy(&grown, buffer)
            buffer = grown
        }

        return offset > 0 ? String(cString: buffer) : nil
    }

    public func readAll(close: Bool = false) -> String {
        defer { if close { _ = pclose(fileStream) } }
        var out = ""
        while let line = readLine(strippingNewline: false) {
            out += line
        }
        return out
    }

    @discardableResult
    public func print(_ items: Any..., separator: String = " ",
                      terminator: String = "\n") -> CInt {
        return fputs(items.map { "\($0)" }.joined(
            separator: separator)+terminator, fileStream)
    }

    @discardableResult
    public func write(data: NSData) -> Int {
        return fwrite(data.bytes, 1, data.count, fileStream)
    }

    @discardableResult
    public func flush() -> CInt {
        return fflush(fileStream)
    }
}
#endif
