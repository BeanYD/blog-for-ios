import UIKit



/**
 集合中的迭代器
 最简单的迭代器 `AnyIterator`
 */
class stateItr: IteratorProtocol {
    var num: Int = 1
    func next() -> Int? {
        num += 2
        return num
    }
}

func findNext<I: IteratorProtocol>( elm: I) -> AnyIterator<I.Element> where I.Element == Int {
    var l = elm
    print("\(l.next() ?? 0)")
    return AnyIterator { l.next() }
    
}

findNext(elm: findNext(elm: findNext(elm: stateItr())))

/// `Collection`


/**
 `map()`的使用
 */

var cats = ["Tabby", "Snow", "Cycloman"]
func wearHat(cat: String) -> String {
    return cat + " wear hat "
}

let catsWithHat = cats.map(wearHat)

/**
 `flatMap()`
 `reduce()`
 `array`--> Array ArraySlice ContiguousArray
 */

/**
 弱引用:数组
 */
let strongArray = NSPointerArray.strongObjects()
let weakArray = NSPointerArray.weakObjects()

/**
 弱引用:Dictionary --> NSMapTable
      Set --> NSHashTable
 */
