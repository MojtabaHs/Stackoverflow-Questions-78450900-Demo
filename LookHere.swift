import Foundation
import SwiftData

extension Optional: Comparable where Wrapped: Comparable {
    public static func < (lhs: Wrapped?, rhs: Wrapped?) -> Bool {
        guard let lhs, let rhs else { return false }
        return lhs < rhs
    }
}

@Model class TodoModel {
    @Attribute(.unique) var id: String
    var taskName: String
    var number: Int?
    var dateStart: Date?
    var dateEnd: Date?
    var isActive: Bool?

    init(id: String, taskName: String, number: Int?, time: Date?) {
        self.id = id
        self.taskName = taskName
        self.number = number
        self.dateStart = time
    }
}

class DatabaseService {
    static let startOfDay = Date()
    static let endOfDay = Date()

    let activePredicate = #Predicate<TodoModel> {
        $0.isActive == true
    }

    let nullCheckPredicate = #Predicate<TodoModel> {
        $0.dateStart != nil && $0.dateEnd != nil
    }

    let rangesPredicates =  #Predicate<TodoModel> {
        ($0.dateStart >= startOfDay && $0.dateStart <= endOfDay) ||
        ($0.dateEnd >= startOfDay && $0.dateEnd <= endOfDay) ||
        ($0.dateStart < startOfDay && $0.dateEnd >= startOfDay)
    }

    static var shared = DatabaseService()
    lazy var container = try! ModelContainer(for: TodoModel.self)
    lazy var context = ModelContext(container)

    var accumulator = 0

    func saveTask(taskName: String?){
        guard let taskName else { return }
        accumulator += 1
        let taskToBeSaved = TodoModel(id: UUID().uuidString, taskName: taskName, number: nil, time: Date())
        context.insert(taskToBeSaved)
    }

    func fetchTasks(onCompletion: @escaping([TodoModel]?, Error?) -> Void)  {
        let combinedPredicate = [activePredicate, nullCheckPredicate, rangesPredicates].conjunction() // 👈 You can use it like this

        let descriptor = FetchDescriptor<TodoModel>(predicate: combinedPredicate)
        do {
            let data = try context.fetch(descriptor)
            onCompletion(data, nil)
        } catch {
            onCompletion(nil, error)
        }
    }
    
    func updateTask(task: TodoModel, newTaskName: String){
        let taskToBeUpdated = task
        taskToBeUpdated.taskName = newTaskName
    }
    
    func deleteTask(task: TodoModel){
        let taskToBeDeleted = task
        context.delete(taskToBeDeleted)
    }
}
