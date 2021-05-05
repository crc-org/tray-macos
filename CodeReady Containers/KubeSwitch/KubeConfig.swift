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
    return (self.yamlContent["current-context"] != nil)
      ? self.yamlContent["current-context"] as! String : ""
  }

  func isCurrentContext(otherContextName: String) -> Bool {
    return otherContextName == self.currentContext()
  }

  func contexts() -> [AnyObject] {
    return (self.yamlContent["contexts"] != nil)
      ? self.yamlContent["contexts"] as! [AnyObject] : []
  }

  func contextNames() -> [String] {
    return self.contexts()
      .map {
        $0 as! [String: Any]
      }
      .map {
        $0["name"] as! String
      }
  }

  func changeContext(newContext: String) {
    self.yamlContent["current-context"] = newContext
  }
}
