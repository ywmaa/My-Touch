extends Node


class Task:
	var id : int
	var joined : bool = false
	signal completed

	func _init(id: int):
		self.id = id

	func get_processed_element_count() -> int:
		return 1 if is_completed() else 0

	func is_completed() -> bool:
		if joined:
			return true
		return WorkerThreadPool.is_task_completed(self.id)

	func wait() -> void:
		joined = true
		WorkerThreadPool.wait_for_task_completion(self.id)


class GroupTask:
	extends Task

	func get_processed_element_count() -> int:
		return WorkerThreadPool.get_group_processed_element_count(self.id)

	func is_completed() -> bool:
		if joined:
			return true
		return WorkerThreadPool.is_group_task_completed(self.id)

	func wait() -> void:
		joined = true
		WorkerThreadPool.wait_for_group_task_completion(self.id)

var tasks := []
var mutex := Mutex.new()

func create_task(action: Callable, high_priority := false, description := "") -> Task:
	var task_id := WorkerThreadPool.add_task(action, high_priority, description)
	var task := Task.new(task_id)
	mutex.lock()
	tasks.append(task)
	mutex.unlock()
	return task


func create_group_task(action: Callable, elements : int, tasks_needed := -1, high_priority := false, description := "") -> GroupTask:
	var group_task_id : int = WorkerThreadPool.add_group_task(action, elements, tasks_needed, high_priority, description)
	var group_task := GroupTask.new(group_task_id)
	mutex.lock()
	tasks.append(group_task)
	mutex.unlock()
	return group_task

func _process(_delta: float) -> void:
	mutex.lock()
	var completed_tasks := tasks.filter(
		func completed(task: Task):
			return task.is_completed()
	)

	for completed_task in completed_tasks:
		var task : Task = completed_task
		task.completed.emit()
		tasks.erase(task)
	mutex.unlock()
