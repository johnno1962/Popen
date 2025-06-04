//
//  Topen.swift
//
//  An abstraction for the api formerly known as NSTask()
//
//  Created by John H on 03/06/2024.
//  Repo: https://github.com/johnno1962/Popen
//  $Id: //depot/Popen/Sources/Popen/Topen.swift#2 $
//

#if DEBUG || !DEBUG_ONLY
#if os(macOS)
import Foundation

open class Topen: Popen {

    open var task: Process
    open var pipe = Pipe()

    /// Alternate version of system() call returning stdout as a stream.
    /// - Parameters:
    ///   - exec: Binary to execute
    ///   - arguments: Arguments to pass to executable
    ///   - cd: working directory.
    /// - Returns: Output of command or errors on failure if errors is true.
    public init(exec: String, arguments: [String] = [], cd: String = "/tmp") {
        task = Process()
        task.launchPath = exec
        task.arguments = arguments
        task.currentDirectoryPath = cd
        task.standardOutput = pipe.fileHandleForWriting
        task.standardError = pipe.fileHandleForWriting
        task.launch()
        close(pipe.fileHandleForWriting.fileDescriptor)
        super.init(stream: fdopen(pipe.fileHandleForReading.fileDescriptor, "r"))
    }

    open override func terminatedOK() -> Bool {
        if exitStatus == nil {
            fclose(fileStream)
            task.waitUntilExit()
            exitStatus = task.terminationStatus
        }
        return exitStatus == EXIT_SUCCESS
    }
}
#endif
#endif
