//
//  Functions.swift
//  MyLocations
//
//  Created by Brang Mai on 2/9/22.
//

import Foundation

func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}
