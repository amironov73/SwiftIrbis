import Foundation

//=========================================================
// TRE-file

class TreeNode {
    var children: [TreeNode]
    var value: String
    var level: Int
    
    init(value: String) {
        self.value = value
        self.children = []
        self.level = 0
    }
} // class TreeNode

class TreeFile {
    var roots: [TreeNode]
    
    init() {
        roots = []
    }
} // class TreeFile

