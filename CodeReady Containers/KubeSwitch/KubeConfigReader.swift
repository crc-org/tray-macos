// Copyright (c) 2019 Sriram Narasimhan
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

import Cocoa
import os.log

class KubeConfigReader {
  let kubeConfigFile = "\(NSHomeDirectory())/.kube/config"

  func read() -> String {
    var contents = ""
    do {
      contents = try String(contentsOfFile: self.kubeConfigFile)
    } catch {
      let errorInfo = "Could not load \(self.kubeConfigFile)"
      os_log("%@", errorInfo)
      let errorDetails = "\(error)"
      os_log("%@", errorDetails)
    }
    return contents
  }

  func write(fileContent: String) {
    do {
      try fileContent.write(toFile: self.kubeConfigFile,
        atomically: true,
        encoding: .utf8)
    } catch {
      let errorInfo = "Could not load write to \(self.kubeConfigFile)"
      os_log("%@", errorInfo)
      let errorDetails = "\(error)"
      os_log("%@", errorDetails)
    }
  }
}
