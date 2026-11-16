class_name ObjectPool
extends RefCounted
## Minimal node pool. Nodes stay in the tree; releasing just hides them and
## stops their processing, so acquire/release never allocates after warm-up.

var _factory: Callable
var _parent: Node
var _free: Array[Node] = []
var total_created: int = 0


func _init(parent: Node, factory: Callable, prewarm: int = 0) -> void:
	_parent = parent
	_factory = factory
	for i in prewarm:
		release(_create())


func _create() -> Node:
	var node: Node = _factory.call()
	_parent.add_child(node)
	total_created += 1
	return node


func acquire() -> Node:
	var node: Node = _free.pop_back() if not _free.is_empty() else _create()
	if node is CanvasItem:
		(node as CanvasItem).visible = true
	return node


func release(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	_free.append(node)


func free_count() -> int:
	return _free.size()
