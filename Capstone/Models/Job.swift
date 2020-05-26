//
//  Job.swift
//  Capstone
//
//  Created by Amy Alsaydi on 5/21/20.
//  Copyright © 2020 Amy Alsaydi. All rights reserved.
//

import Foundation

struct Job {
    var test: String
}

extension Job {
    init(_ dictionary: [String: Any]) {
        self.test = dictionary["test"] as? String ?? "no material type"
    }
}