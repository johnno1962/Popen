//
//  Stat.swift
//
//  Created by John Holdsworth on 03/12/2023.
//  Repo: https://github.com/johnno1962/Popen
//
//  Simple way to get information on file.
//

import Foundation

public typealias Fstat = stat

extension Fstat {
    public init?(path: String) {
        self.init()
        if stat(path, &self) != 0 {
            return nil
        }
    }
    public init?(fd: CInt) {
        self.init()
        if fstat(fd, &self) != 0 {
            return nil
        }
    }
    public init?(link: String) {
        self.init()
        if lstat(link, &self) != 0 {
            return nil
        }
    }
}
