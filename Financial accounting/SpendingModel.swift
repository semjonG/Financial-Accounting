//
//  SpendingModel.swift
//  Financial accounting
//
//  Created by mac on 09.01.2022.
//

import RealmSwift

// LocalOnlyQsTask is the Task model for this QuickStart
class Spending: Object {
    @Persisted var category: String = ""
    @Persisted var price: Int
    @Persisted var date: Date
}

class Limit: Object {
    @Persisted var limitMoney: String = ""
    @Persisted var limitDate: Date
    @Persisted var limitLastDay: Date
}
