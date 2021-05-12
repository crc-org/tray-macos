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

import Yams
import os.log

class YamlReader {
  func loadKubeConfig(yaml: String) -> KubeConfig {
    do {
      let readYaml = try Yams.load(yaml: yaml)
      let yamlContent = readYaml != nil ? readYaml as! [String: Any] : [:]
      return KubeConfig(yamlContent: yamlContent)
    } catch {
      os_log("Could not load yaml string as dictionary", type: .error)
      let errorDetails = "\(error)"
      os_log("%@", errorDetails)
    }
    return KubeConfig(yamlContent: [:])
  }

  func dumpString(object: Any) -> String {
    var yamlString = ""
    do {
      yamlString = try Yams.dump(object: object)
    } catch {
      os_log("Could not convert yaml dictionary as string", type: .error)
      let errorDetails = "\(error)"
      os_log("%@", errorDetails)
    }
    return yamlString
  }
}
