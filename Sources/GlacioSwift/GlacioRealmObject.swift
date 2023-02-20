//
//  GlacioObject.swift
//  Glacio
//
//  Created by Peter Liddle on 1/26/23.
//

import Foundation
import RealmSwift

/// Glacio compatible Realm Object. Any realm objects being stored in Glacio must adhere to this protocol 
public protocol GlacioRealmObject: Object, Identifiable, Codable {}
