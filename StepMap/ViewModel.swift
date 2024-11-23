//
//  ViewModel.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import Foundation

class ViewModel: ObservableObject {
    @Published var test: String = UserDefaults.standard.string(forKey: "test") ?? ""
    
    func saveValue(_ value: String) {
        UserDefaults.standard.set(value, forKey: "test")
        test = value
    }
}
