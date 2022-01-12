//
//  ViewController.swift
//  Financial accounting
//
//  Created by mac on 01.01.2022.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {
    
//    массив для хранения всех значений в базе данных и через него производим чтение и запись данных
    var spendingArray: Results<Spending>!

//    экземпляр Realm
    let localRealm = try! Realm()

    @IBOutlet weak var limitLabel: UILabel!
    
    @IBOutlet weak var availableMoney: UILabel!
    
    @IBOutlet weak var expensesForThePeriod: UILabel!
    
    @IBOutlet weak var displayLabel: UILabel!
     
    @IBOutlet weak var allSpending: UILabel!
    
    var stillTyping = false
    
    var categoryName = ""
    var displayValue: Int = 1
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        при загрузке приложения все данные попадают в spendingArray - экземпляр модели (self - т.к. все происходит внутри цикла)
        spendingArray = localRealm.objects(Spending.self)
        
        leftLabels()
//        отображение всех расходов сразу
        allExpenses()
    }
    
    @IBOutlet var numberFromKeyboard: [UIButton]! {
        didSet {
            for button in numberFromKeyboard {
                button.layer.cornerRadius = 11
            }
        }
    }
    
    @IBAction func numberPressed(_ sender: UIButton) {
        let number = sender.currentTitle!
        
        if number == "0" && displayLabel.text == "0" {
            stillTyping = false
        } else {
            
            if stillTyping {
                if displayLabel.text!.count < 15 {
                    displayLabel.text = displayLabel.text! + number
                }
            } else {
                displayLabel.text = number
                stillTyping = true
            }
        }
    }
    
    @IBAction func resetButton(_ sender: UIButton) {
        displayLabel.text = "0"
        stillTyping = false
    }
    
    @IBAction func categoryPressed(_ sender: UIButton) {
        categoryName = sender.currentTitle!
        displayValue = Int(displayLabel.text!)!
        displayLabel.text = "0"
        stillTyping = false
        
//        запись данных в определенном порядке (категория -> вводимое значение/цена)
        let value = Spending(value: ["\(categoryName)", displayValue])
        try! localRealm.write {
            localRealm.add(value)
        }
        leftLabels()
        allExpenses()
        tableView.reloadData() 
    }
    
    @IBAction func limitPressed(_ sender: UIButton) {
//        создание alertController
        let alertController = UIAlertController (title: "Установите лимит", message: "Введите сумму и количество дней", preferredStyle: .alert)
//         загрузка введенных значений в базу данных и их отображение
        let alertInstall = UIAlertAction(title: "Установить", style: .default) { action in
//         лимитная сумма денег в текстфилде
            let limitAmount = alertController.textFields?[0].text
            
            
//         кол-во дней в текстфилде
            let numberOfDays = alertController.textFields?[1].text
            
//            проверка на незаполненные текстфилды
            guard numberOfDays != "" && limitAmount != "" else { return }
            
            self.limitLabel.text = limitAmount
            
            if let day = numberOfDays {
                let dateNow = Date()
                let lastDay: Date = dateNow.addingTimeInterval(60*60*24*Double(day)!)
                
//                условия содержания записей в базе данных
                let limit = self.localRealm.objects(Limit.self)
                
                if limit.isEmpty == true {
                    let value = Limit(value: [self.limitLabel.text!, dateNow, lastDay])
                    try! self.localRealm.write {
                        self.localRealm.add(value)
                    }
                } else {
                    try! self.localRealm.write {
                        limit[0].limitMoney = self.self.limitLabel.text!
                        limit[0].limitDate = dateNow as Date
                        limit[0].limitLastDay = lastDay as Date
                    }
                }
            }
//            обновляем лейблы после установки нового лимита
            self.leftLabels()
        }
        
//        создание текстовых полей
        alertController.addTextField { (money) in
            money.placeholder = "Денежный лимит"
            money.keyboardType = .numberPad
        }
        alertController.addTextField { (days) in
            days.placeholder = "Количество дней"
            days.keyboardType = .numberPad
        }
        
//        отмена
        let alertCancel = UIAlertAction(title: "Отмена", style: .default) { _ in }
        
//        вызываем действия
        alertController.addAction(alertInstall)
        alertController.addAction(alertCancel)
        
//        вызываем весь алертконтроллер
        present(alertController, animated: true, completion: nil)
    }
    
//    функция отвечает за всю логику, которая происходит с лейблами
    func leftLabels() {
//        свойство, через которое мы обращаемся к базе данных Limit
        let limit = self.localRealm.objects(Limit.self)
        
//        проверка при открытии приложения: если limit пустой и это неправда, то происходит выполнение кода далее. если правда, то выходим из метода
        guard limit.isEmpty == false else { return }
        
//        берем первое значение из БД
        limitLabel.text = limit[0].limitMoney
        
//        указываем компилятору, какой календарь используем
        let calendar = Calendar.current
        
//        выбираем только нужные нам параметры исчисления времени
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        
//        обращаемся к двум датам (первой и последней)
        let firstDay = limit[0].limitDate
        let lastDay = limit[0].limitLastDay
        
//        преобразование формата даты в нужный при помощи dateComponents
        let firstComponents = calendar.dateComponents([.year, .month, .day], from: firstDay)
        let lastComponents = calendar.dateComponents([.year, .month, .day], from: lastDay)
        
//        выборка из базы данных Spending (сложение всех price за заданное кол-во дней)
//        задаем две даты (дату начала и конца)
        let startDate = formatter.date(from: "\(firstComponents.year!)/\(firstComponents.month!)/\(firstComponents.day!) 00:00") as Any
        let endDate = formatter.date(from: "\(lastComponents.year!)/\(lastComponents.month!)/\(lastComponents.day!) 00:00") as Any
        
//        выборка: дата должна быть больше или равна startDate и меньше или равна endDate. далее суммируем значения трат
        let filtredLimit: Int = localRealm.objects(Spending.self).filter("self.date >= %@ && self.date <= %@", startDate, endDate).sum(ofProperty: "price")
        
//        записываем сюда все траты за промежуток времени
        expensesForThePeriod.text = "\(filtredLimit)"
        
//        расчет доступных средств для трат
        let a = Int(limitLabel.text!)!
        let b = Int(expensesForThePeriod.text!)!
        let c = a - b
        
        availableMoney.text = "\(c)"
    }
    
    func allExpenses() {
        //        отображение всех расходов, даже если не установлен лимит трат
        let allExpenses: Int = localRealm.objects(Spending.self).sum(ofProperty: "price")
        allSpending.text = "\(allExpenses)"
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
//    указываем кол-во ячеек в таблице
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spendingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        в конце делаем приведение типов для получения доступа к аутлетам
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
//        чтобы ячейки в таблице и записи в массиве совпадали по индексу
        let spendingCell = spendingArray.sorted(byKeyPath: "date", ascending: false)[indexPath.row]
        
//        указываем значения лейблов в таблице
        cell.recordCategory.text = spendingCell.category
        cell.recordPrice.text = "\(spendingCell.price)"
        
//        в зависимости от названия категории картинка будет подстраиваться под значение
        switch spendingCell.category {
        case "Еда": cell.recordImage.image = UIImage(named: "Category_Еда")
        case "Одежда": cell.recordImage.image = UIImage(named: "Category_Одежда")
        case "Связь": cell.recordImage.image = UIImage(named: "Category_Связь")
        case "Досуг": cell.recordImage.image = UIImage(named: "Category_Досуг")
        case "Красота": cell.recordImage.image = UIImage(named: "Category_Красота")
        case "Авто": cell.recordImage.image = UIImage(named: "Category_Авто")
        default: cell.recordImage.image = UIImage(named: "Display1")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let editingRow = spendingArray.sorted(byKeyPath: "date", ascending: false)[indexPath.row]
        
//        удаление записи из таблицы и затем из базы данных
        let deleteAction = UITableViewRowAction(style: .destructive,
                                                title: "Удалить") { (_, _) in
            try! self.localRealm.write {
                self.localRealm.delete(editingRow)
                self.leftLabels()
                self.allExpenses()
                tableView.reloadData()
            }
        }
        return [deleteAction]
    }

}

    

