// Original work Copyright (c) 2019 Sriram Narasimhan
// Modified work Copyright 2020 Red Hat
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

class KubeConfig {
  var yamlContent: [String: Any]

  init(yamlContent: [String: Any]) {
    self.yamlContent = yamlContent
  }

  func currentContext() -> String {
    if let ret =  self.yamlContent["current-context"] as? String {
        return ret
    } else {
        return ""
    }
  }

  func isCurrentContext(otherContextName: String) -> Bool {
    return otherContextName == self.currentContext()
  }

  func contexts() -> [AnyObject] {
    if let ret =  self.yamlContent["contexts"] as? [AnyObject] {
        return ret
    } else {
        return []
    }
  }

  func contextNames() -> [String] {
    return self.contexts()
      .map {
        $0 as? [String: Any]
      }
      .compactMap { $0 }
      .map {
        $0["name"] as? String
      }
      .compactMap { $0 }
  }

  func changeContext(newContext: String) {
    self.yamlContent["current-context"] = newContext
  }
}
