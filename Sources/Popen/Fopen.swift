//
//  Fopen.swift
//  Popen
//
//  Created by John Holdsworth on 29/10/2023.
//  Repo: https://github.com/johnno1962/Popen
//
//  Abstractions on stdio files born out of
//  frustration with the woeful NSFileHandle.
//

import Foundation

open class Fopen: FILEStream, Sequence, IteratorProtocol {
    public enum FILEMode: String {
        case read = "r"
        case both = "r+"
        case write = "w"
        case append = "a"
        case new = "wx"
    }

    public enum FILESeek {
        case absolute(_ offset: Int)
        case relative(_ offset: Int)
        case fromEnd(_ offset: Int)
        var args: (offset: Int, whence: CInt) {
            switch self {
            case .absolute(let offset):
                return (offset, SEEK_SET)
            case .relative(let offset):
                return (offset, SEEK_CUR)
            case .fromEnd(let offset):
                return (offset, SEEK_END)
            }
        }
    }

    open var streamHandle: UnsafeMutablePointer<FILE>

    public init?(stream: UnsafeMutablePointer<FILE>?) {
        guard let stream = stream else { return nil }
        streamHandle = stream
        openFILEStreams += 1
    }

    public convenience init?(path: String, mode: FILEMode = .read) {
        self.init(stream: fopen(path, mode.rawValue))
    }

    public convenience init?(fd: CInt, mode: FILEMode = .read) {
        self.init(stream: fdopen(fd, mode.rawValue))
    }

    public convenience init?(buffer: UnsafeMutableRawPointer,
                             count: Int, mode: FILEMode = .read) {
        self.init(stream: fmemopen(buffer, count, mode.rawValue))
    }

    #if canImport(Darwin)
    public convenience init?(cookie: UnsafeRawPointer?,
        reader: @convention(c) (
            _ cookie: UnsafeMutableRawPointer?,
            _ buffer: UnsafeMutablePointer<CChar>?,
            _ count: CInt) -> CInt,
        writer: @convention(c) (
            _ cookie: UnsafeMutableRawPointer?,
            _ buffer: UnsafePointer<CChar>?,
            _ count: CInt) -> CInt,
        seeker: @convention(c) (
            _ cookie: UnsafeMutableRawPointer?,
            _ position: fpos_t,
            _ relative: CInt) -> fpos_t,
        closer: @convention(c) (
            _ cookie: UnsafeMutableRawPointer?) -> CInt) {
        self.init(stream: funopen(cookie, reader, writer, seeker, closer))
    }
    #endif

    open func seek(to position: FILESeek) -> CInt {
        let args = position.args
        return fseek(streamHandle, args.offset, args.whence)
    }

    open func tell() -> Int {
        return ftell(streamHandle)
    }

    deinit {
        _ = fclose(streamHandle)
        openFILEStreams -= 1
    }
}
