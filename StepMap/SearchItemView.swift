//
//  SearchItemView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import MapKit
import SwiftUI

struct SearchItemView: View {
    var location: MKMapItem

    var body: some View {
        Text("\(location.name ?? "")")
    }
}
