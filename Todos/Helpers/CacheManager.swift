//
//  CacheManager.swift
//  Todos
//
//  Created by Bektemur Mamashayev on 26/02/25.
//

import Foundation

final class CacheManager {
    private let todosCache = NSCache<NSString, NSArray>()
    private let usersCache = NSCache<NSString, NSArray>()
    
    func saveTodos(_ todos: [Todo]) {
        todosCache.setObject(todos as NSArray, forKey: "cachedTodos")
    }

    func getCachedTodos() -> [Todo]? {
        return todosCache.object(forKey: "cachedTodos") as? [Todo]
    }

    func saveUsers(_ users: [User]) {
        usersCache.setObject(users as NSArray, forKey: "cachedUsers")
    }

    func getCachedUsers() -> [User]? {
        return usersCache.object(forKey: "cachedUsers") as? [User]
    }
}
